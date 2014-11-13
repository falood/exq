defmodule ExQ.Adapter do
  use Behaviour

  defcallback start_repo(Keyword.t) :: :ok
  defcallback parse_where(Keyword.t | Map.t) :: String.t
  defcallback parse_where(String.t, List.t) :: String.t
  defcallback parse_query(Q.t) :: String.t
  defcallback table_struct(Keyword.t, String.t) :: Keyword.t
  defcallback select(Q.t) :: Map.t
  defcallback insert(Map.t) :: Map.t
  defcallback update(Map.t) :: Map.t
  defcallback delete(Q.t | Map.t | [Map.t]) :: :ok
end
