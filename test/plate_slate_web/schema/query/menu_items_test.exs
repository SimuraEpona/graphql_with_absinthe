defmodule PlateSlateWeb.Schema.Query.MenuItemsTest do
  use PlateSlateWeb.ConnCase, async: true

  setup do
    PlateSlate.Seeds.run()
  end

  @query """
  {
    menuItems {
      name
    }
  }
  """

  test "menuItems field returns menu items" do
    conn = build_conn()

    conn = post conn, "/api", query: @query

    assert json_response(conn, 200) == %{
             "data" => %{
               "menuItems" => [
                 %{"name" => "Bánh mì"},
                 %{"name" => "Chocolate Milkshake"},
                 %{"name" => "Croque Monsieur"},
                 %{"name" => "French Fries"},
                 %{"name" => "Lemonade"},
                 %{"name" => "Masala Chai"},
                 %{"name" => "Muffuletta"},
                 %{"name" => "Papadum"},
                 %{"name" => "Pasta Salad"},
                 %{"name" => "Reuben"},
                 %{"name" => "Soft Drink"},
                 %{"name" => "Thai Salad"},
                 %{"name" => "Vada Pav"},
                 %{"name" => "Vanilla Milkshake"},
                 %{"name" => "Water"}
               ]
             }
           }
  end

  @query """
  {
    menuItems(order: DESC) {
      name
    }
  }
  """

  test "menuItems field returns items descending using literals" do
    response = post(build_conn(), "/api", query: @query)

    assert %{
             "data" => %{"menuItems" => [%{"name" => "Water"} | _]}
           } = json_response(response, 200)
  end

  @query """
  {
    menuItems(filter: { category: "Sandwiches", tag: "Vegetarian" }) {
      name
    }
  }
  """

  test "menuItems field returns menuItems, filtering with a literal" do
    response = post(build_conn(), "/api", query: @query)

    assert %{
             "data" => %{"menuItems" => [%{"name" => "Vada Pav"}]}
           } == json_response(response, 200)
  end

  @query """
  query($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
    }
  }
  """
  @variables %{filter: %{"tag" => "Vegetarian", "category" => "Sandwiches"}}
  test "menuItems field returns menuItems, filtering with a variable" do
    response = post(build_conn(), "/api", query: @query, variables: @variables)

    assert %{
             "data" => %{"menuItems" => [%{"name" => "Vada Pav"}]}
           } == json_response(response, 200)
  end

  @query """
  query($filter: MenuItemFilter!) {
    menuItems(filter: $filter) {
      name
      addedOn
    }
  }
  """

  @variables %{filter: %{"addedBefore" => "2017-01-20"}}
  test "menuItems filtered by custom scalar" do
    sides = PlateSlate.Repo.get_by!(PlateSlate.Menu.Category, name: "Sides")

    %PlateSlate.Menu.Item{
      name: "Garlic Fries",
      added_on: ~D[2017-01-01],
      price: 2.50,
      category: sides
    }
    |> PlateSlate.Repo.insert!()

    response = post(build_conn(), "/api", query: @query, variables: @variables)

    assert %{
             "data" => %{"menuItems" => [%{"name" => "Garlic Fries", "addedOn" => "2017-01-01"}]}
           } == json_response(response, 200)
  end

  @variables %{filter: %{"addedBefore" => "not-a-date"}}
  test "menuItems filtered by custom scalar with error" do
    response = post(build_conn(), "/api", query: @query, variables: @variables)

    assert %{
             "errors" => [
               %{
                 "locations" => [%{"column" => _, "line" => _}],
                 "message" => message
               }
             ]
           } = json_response(response, 200)

    expected = """
    Argument "filter" has invalid value $filter.
    In field "addedBefore": Expected type "Date", found "not-a-date".\
    """

    assert expected == message
  end

  @query """
  query ($order: SortOrder!) {
    menuItems(order: $order) {
      name
    }
  }
  """

  @variables %{"order" => "DESC"}
  test "menuItems field returns menu items descending using a variable" do
    response = post(build_conn(), "/api", query: @query, variables: @variables)

    assert %{
             "data" => %{"menuItems" => [%{"name" => "Water"} | _]}
           } = json_response(response, 200)
  end
end
