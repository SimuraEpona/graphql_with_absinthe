defmodule PlateSlateWeb.Resolvers.Menu do
  alias PlateSlate.Menu

  import Absinthe.Resolution.Helpers, only: [on_load: 2]

  def menu_items(_, args, _) do
    {:ok, Menu.list_items(args)}
  end

  def items_for_category(category, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(Menu, {:items, args}, category)
    |> on_load(fn loader ->
      items = Dataloader.get(loader, Menu, {:items, args}, category)
      {:ok, items}
    end)
  end

  def category_for_item(menu_item, _, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(Menu, :category, menu_item)
    |> on_load(fn loader ->
      category = Dataloader.get(loader, Menu, :category, menu_item)
      {:ok, category}
    end)
  end

  def search(_, %{matching: term}, _) do
    {:ok, Menu.search(term)}
  end

  def create_item(_, %{input: params}, _) do
    with {:ok, item} <- Menu.create_item(params) do
      {:ok, %{menu_item: item}}
    end
  end

  def get_item(_, %{id: id}, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(Menu, Menu.Item, id)
    |> on_load(fn loader ->
      {:ok, Dataloader.get(loader, Menu, Menu.Item, id)}
    end)
  end
end
