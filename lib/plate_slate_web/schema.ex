defmodule PlateSlateWeb.Schema do
  use Absinthe.Schema
  alias PlateSlateWeb.Resolvers

  ## CH05 add decimal, doesn't work well in Phoenix v1.6 & absinthe 1.7.0
  ## instead use import_types Absinthe.Type.Custom
  ## it adds datetime(UTC), naive_datetime date time and decimal data types
  import_types(Absinthe.Type.Custom)
  import_types(__MODULE__.MenuTypes)

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

  enum :sort_order do
    value(:asc)
    value(:desc)
  end
end
