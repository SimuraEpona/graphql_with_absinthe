defmodule PlateSlateWeb.Schema do
  use Absinthe.Schema
  alias PlateSlateWeb.Resolvers

  import_types(__MODULE__.MenuTypes)
  import_types(Absinthe.Type.Custom)

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
  end

  mutation do
    field :create_menu_item, :menu_item do
      arg(:input, non_null(:menu_item_input))
      resolve(&Resolvers.Menu.create_item/3)
    end
  end

  ## CH05 add decimal, doesn't work well in Phoenix v1.6 & absinthe 1.7.0
  ## instead use import_types Absinthe.Type.Custom
  ## it adds datetime(UTC), naive_datetime date time and decimal data types

  # scalar :decimal do
  #   parse(fn
  #     %{value: value}, _ ->
  #       Decimal.parse(value)
  #     _, _ ->
  #       :error
  #   end)

  #   serialize(&to_string/1)
  # end

  # scalar :date do
  #   parse(fn input ->
  #     with %Absinthe.Blueprint.Input.String{value: value} <- input,
  #          {:ok, date} <- Date.from_iso8601(value) do
  #       {:ok, date}
  #     else
  #       _ -> :error
  #     end
  #   end)

  #   serialize(fn date ->
  #     Date.to_iso8601(date)
  #   end)
  # end

  enum :sort_order do
    value(:asc)
    value(:desc)
  end
end
