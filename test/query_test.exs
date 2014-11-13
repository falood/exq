defmodule ExQ.QueryTest do
  use ExUnit.Case

  defp new_query, do: Q.new [from: "tests", repo: [adapter: ExQ.Adapters.MySQL]]

  test "select" do
    assert %Q{select: [:id, :name]} = new_query |> Q.select([:id, :name])
  end

  test "where" do
    assert %Q{where: "`id`='1'"} = new_query |> Q.where([id: 1])
    assert %Q{where: "id = '1'"} = new_query |> Q.where("id = ?", [1])
  end

  test "limit" do
    assert %Q{limit: 1} = new_query |> Q.limit(1)
  end

  test "offset" do
    assert %Q{offset: 10} = new_query |> Q.offset(10)
  end

  test "order" do
    assert %Q{order: {:id, :asc}}  = new_query |> Q.order(:id)
    assert %Q{order: {:id, :desc}} = new_query |> Q.order(:id, :desc)
  end

  test "multi" do
    assert %Q{ select: [:id], limit: 10, offset: 100, order: {:id, :desc}, where: "id > '3'" }
      = new_query |> Q.select([:id]) |> Q.where("id > :id", [id: 3]) |> Q.offset(100) |> Q.limit(10) |> Q.order(:id, :desc)
  end

  defmodule Elixir.M do
    use ExQ.Model, table_name: "test"
  end

  test "save update" do
    assert %M{} = %{M.first | string: "SAVE UPDATE"} |> Q.save
  end

  test "save insert" do
    assert %M{} = %M{string: "SAVE INSERT", float: "100.001"} |> Q.save
  end
end
