defmodule Q do
  # http://guides.rubyonrails.org/active_record_querying.html
  [ repo: nil, model: nil, from: nil, select: nil, where: nil,
    offset: nil, limit: nil, order: nil, count: false
  ] |> defstruct

  def new(q) do
    struct(__MODULE__, q)
  end


  def select(q, s) do
    %{q | select: s}
  end


  def where(q, x) do
    %{q | where: q.repo[:adapter].parse_where(x)}
  end

  def where(q, x, y) do
    %{q | where: q.repo[:adapter].parse_where(x, y)}
  end


  def offset(q, x) do
    %{q | offset: x}
  end

  def limit(q, x) do
    %{q | limit: x}
  end


  def order(q, field, direction \\ :asc) do
    %{q | order: {field, direction}}
  end

  def count(q) do
    %{q | count: true} |> select
  end

  def first(q, num \\ 1) do
    %{q | limit: num} |> select |> List.first
  end

  def all(q) do
    q |> select
  end


  def update(record, params) do
    record |> Dict.merge(params) |> save
  end


  def save(record) do
    pk = record.__struct__.__pk__
    adapter = record.__struct__.__repo__[:adapter]
    case record |> Map.get(pk) do
      nil -> record |> adapter.insert
      _   -> record |> adapter.update
    end
  end


  defp select(q) do
    q |> q.repo[:adapter].select
  end
end
