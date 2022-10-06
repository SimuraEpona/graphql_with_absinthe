defmodule PlateSlateWeb.ItemController do
  use PlateSlateWeb, :controller
  use Absinthe.Phoenix.Controller, schema: PlateSlateWeb.Schema, action: [mode: :internal]

  alias PlateSlate.Menu
  alias PlateSlate.Menu.Item

  @graphql """
  query {
    menu_items @put {
      category
      order_history {
        quantity
      }
    }
  }
  """
  def index(conn, result) do
    result |> IO.inspect()

    render(conn, "index.html", items: result.data.menu_items)
  end

  def new(conn, _params) do
    changeset = Menu.change_item(%Item{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"item" => item_params}) do
    case Menu.create_item(item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "Item created successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  @graphql """
  query($id: ID!, $since: Date) {
    menu_item(id: $id) @put {
      order_history(since: $since) {
        quantity
        gross
        orders
      }
    }
  }
  """
  def show(conn, %{data: %{menu_item: nil}}) do
    conn
    |> put_flash(:info, "Menu item not found")
    |> redirect(to: "/admin/items")
  end

  def show(conn, %{data: %{menu_item: item}}) do
    since = variables(conn)["since"] || "2018-01-01"
    render(conn, "show.html", item: item, since: since)
  end

  def edit(conn, %{"id" => id}) do
    item = Menu.get_item!(id)
    changeset = Menu.change_item(item)
    render(conn, "edit.html", item: item, changeset: changeset)
  end

  def update(conn, %{"id" => id, "item" => item_params}) do
    item = Menu.get_item!(id)

    case Menu.update_item(item, item_params) do
      {:ok, item} ->
        conn
        |> put_flash(:info, "Item updated successfully.")
        |> redirect(to: Routes.item_path(conn, :show, item))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", item: item, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    item = Menu.get_item!(id)
    {:ok, _item} = Menu.delete_item(item)

    conn
    |> put_flash(:info, "Item deleted successfully.")
    |> redirect(to: Routes.item_path(conn, :index))
  end
end
