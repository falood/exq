defmodule ExQ.Adapters.MySQLTest do
  use ExUnit.Case
  alias ExQ.Adapters.MySQL

  test "parse where" do
    assert MySQL.parse_where("a > 1") == "a > 1"
    assert MySQL.parse_where([a: 1, b: 2]) == "`a`='1' and `b`='2'"
    assert MySQL.parse_where(%{a: 1, b: 2}) == "`a`='1' and `b`='2'"
    assert MySQL.parse_where("a = ? and b > ?", [1, 2]) == "a = '1' and b > '2'"
    assert MySQL.parse_where("a = :a and b > :b", [a: 1, b: 2]) == "a = '1' and b > '2'"
    assert MySQL.parse_where("a = :a and b > :b", %{a: 1, b: 2}) == "a = '1' and b > '2'"
  end

  test "parse query" do
    assert MySQL.parse_query(
      %Q{select: [:id], from: "test", limit: 10, offset: 100, order: {:id, :desc}, where: "id > '3'"}
    ) == "SELECT `id` FROM `test` WHERE id > '3' ORDER BY `id` DESC OFFSET 100 LIMIT 10"
    assert MySQL.parse_query(
      %Q{select: [:id], from: "test", limit: 10, where: "id > '3'", count: true}
    ) == "SELECT COUNT(*) FROM `test` WHERE id > '3' LIMIT 10"
  end

  defmodule M do
    use ExQ.Model, table_name: "test"
  end

  test "insert" do
    %M{id: id} = %M{datetime: {:datetime, {{2014, 9, 26}, {10, 0, 0}}}, float: 1.0001} |> MySQL.insert
    assert is_integer(id)

    %M{id: id} = %M{float: 1.0001, string: "HEHEHE"} |> MySQL.insert
    assert is_integer(id)
  end

  test "select" do
    assert %M{} = M.first
  end

  test "update" do
    assert %M{string: "HEHE"} = %{M.first | string: "HEHE"} |> MySQL.update
  end

  test "delete record" do
    assert :ok == M.first |> MySQL.delete
  end

  test "delete query" do
    assert [:ok] == M.limit(1) |> MySQL.delete
  end
end
