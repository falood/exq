defmodule ExQ do
  use Application

  def start(_type, _args) do
    for repo <- ExQ.Config.repos do
      {adapter, repo} = repo |> Dict.pop :adapter
      repo |> adapter.start_repo
    end
    {:ok, self}
  end
end
