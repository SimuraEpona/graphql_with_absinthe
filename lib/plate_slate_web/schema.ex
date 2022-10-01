defmodule PlateSlateWeb.Schema do
  use Absinthe.Schema
  alias PlateSlateWeb.Resolvers
  alias PlateSlateWeb.Schema.Middleware

  ## CH05 add decimal, doesn't work well in Phoenix v1.6 & absinthe 1.7.0
  ## instead use import_types Absinthe.Type.Custom
  ## it adds datetime(UTC), naive_datetime date time and decimal data types
  import_types(Absinthe.Type.Custom)
  import_types(__MODULE__.MenuTypes)
  import_types(__MODULE__.OrderingTypes)
  import_types(__MODULE__.AccountsTypes)

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  def middleware(middleware, field, object) do
    middleware
    |> apply(:errors, field, object)
    |> apply(:get_string, field, object)
    |> apply(:debug, field, object)
  end

  defp apply(middleware, :errors, _field, %{identifier: :mutation}) do
    middleware ++ [Middleware.ChangesetErrors]
  end

  defp apply([], :get_string, field, %{identifier: :allergy_info}) do
    [{Absinthe.Middleware.MapGet, to_string(field.identifier)}]
  end

  defp apply(middleware, :debug, _field, _object) do
    if System.get_env("DEBUG") do
      [{Middleware.Debug, :start}] ++ middleware
    else
      middleware
    end
  end

  defp apply(middleware, _, _, _) do
    middleware
  end

  def dataloader() do
    alias PlateSlate.Menu

    Dataloader.new()
    |> Dataloader.add_source(Menu, Menu.data())
  end

  def context(ctx) do
    Map.put(ctx, :loader, dataloader())
  end

  query do
    @desc "The list of available items on the menu"
    field :menu_items, list_of(:menu_item) do
      arg(:filter, :menu_item_filter)
      arg(:order, type: :sort_order, default_value: :asc)
      resolve(&Resolvers.Menu.menu_items/3)
    end

    field :search, list_of(:search_result) do
      arg(:matching, non_null(:string))
      resolve(&Resolvers.Menu.search/3)
    end

    field :me, :user do
      middleware(Middleware.Authorize, :any)
      resolve(&Resolvers.Accounts.me/3)
    end
  end

  mutation do
    field :login, :session do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      arg(:role, non_null(:role))
      resolve(&Resolvers.Accounts.login/3)

      middleware(fn res, _ ->
        with %{value: %{user: user}} <- res do
          %{res | context: Map.put(res.context, :current_user, user)}
        end
      end)
    end

    field :create_menu_item, :menu_item_result do
      arg(:input, non_null(:menu_item_input))
      middleware(Middleware.Authorize, "employee")
      resolve(&Resolvers.Menu.create_item/3)
      middleware(Middleware.ChangesetErrors)
    end

    field :place_order, :order_result do
      arg(:input, non_null(:place_order_input))
      middleware(Middleware.Authorize, :any)
      resolve(&Resolvers.Ordering.place_order/3)
    end

    field :ready_order, :order_result do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Ordering.ready_order/3)
    end

    field :complete_order, :order_result do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Ordering.complete_order/3)
    end
  end

  subscription do
    field :new_order, :order do
      config(fn _args, %{context: context} ->
        case context[:current_user] do
          %{role: "customer", id: id} ->
            {:ok, topic: id}

          %{role: "employee"} ->
            {:ok, topic: "*"}

          _ ->
            {:error, "unauthorized"}
        end
      end)
    end

    field :update_order, :order do
      arg(:id, non_null(:id))

      config(fn args, _info ->
        {:ok, topic: args.id}
      end)

      trigger([:ready_order, :complete_order],
        topic: fn
          %{order: order} -> [order.id]
          _ -> []
        end
      )

      resolve(fn %{order: order}, _, _ ->
        {:ok, order}
      end)
    end
  end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end
end
