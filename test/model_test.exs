defmodule ExQ.ModelTest do
  use ExUnit.Case

  test "model" do
    defmodule M do
      use ExQ.Model, table_name: "test"
    end

    assert [ pool: :exq_default_repo, password: "root", host: "127.0.0.1",
             database: "exq_test", adapter: ExQ.Adapters.MySQL, port: 3306, username: "root"
           ] == M.__repo__

    assert :id == M.__pk__

    assert "test" == M.__table_name__
  end
end
