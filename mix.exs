defmodule Mix.Tasks.Compile.Q do
  def run(_) do
    Application.ensure_all_started :exq
  end
end

defmodule ExQ.Mixfile do
  use Mix.Project

  def project do
    [ app: :exq,
      version: "0.0.1",
      elixir: "~> 1.0.0",
      compilers: [ :elixir, :app, :q ],
      deps: deps
    ]
  end

  def application do
    [ mod: { ExQ, [] },
      applications: [ :logger, :emysql ]
    ]
  end

  defp deps do
    [{ :emysql, github: "Eonblast/Emysql", ref: "c7e2103" }]
  end
end
