defmodule ExQ.Config do
  {default_repo, repos} =
    Application.get_all_env(:exq)
 |> Dict.split([:adapter, :host, :port, :database, :username, :password])

  @repos [{:exq_default_repo, default_repo} | repos] |> Enum.filter_map(
    fn {_, repo}    -> repo[:adapter] in [:mysql, :postgres] end,
    fn {pool, repo} ->
      adapter = [ mysql: ExQ.Adapters.MySQL,
                  postgres: ExQ.Adapters.Postgres
                ] [repo[:adapter]]
      {pool, repo |> put_in([:adapter], adapter) |> put_in([:pool], pool)}
    end
  )

  def repos do
    for {_pool, repo} <- @repos do repo end
  end
  def repos(r), do: @repos[r]
end
