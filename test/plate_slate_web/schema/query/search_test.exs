defmodule PlateSlateWeb.Schema.Query.SearchTest do
  use PlateSlateWeb.ConnCase, async: true

  setup do
    PlateSlate.Seeds.run()
  end

  @query """
  query search($term: String!) {
    search(matching: $term) {
      name
      __typename
    }
  }
  """

  @variables %{term: "e"}
  test "search returns a list of menu items and categories" do
    response = post(build_conn(), "/api", query: @query, variables: @variables)
    assert %{"data" => %{"search" => results}} = json_response(response, 200)

    assert length(results) > 0
    assert Enum.find(results, &(&1["__typename"] == "Category"))
    assert Enum.find(results, &(&1["__typename"] == "MenuItem"))
    assert Enum.all?(results, & &1["name"])
  end
end
