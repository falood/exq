defmodule ExQ.RecordNotFound do
  defexception []
  def message(_), do: "RecordNotFound"
end

defmodule ExQ.SQLRuntimeError do
  defexception [msg: ""]
  def message(exception), do: exception[:msg]
end
