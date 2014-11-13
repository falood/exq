defimpl Enumerable, for: Q do
  def reduce(query, acc, fun) do
    query |> Q.exec |> Enumerable.reduce(acc, fun)
  end

  def member?(_query, _e) do
    {:error, __MODULE__}
  end

  def count(_query) do
    {:error, __MODULE__}
  end
end
