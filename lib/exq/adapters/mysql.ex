defmodule ExQ.Adapters.MySQL do
  @behaviour ExQ.Adapter

  def start_repo(opts) do
    :emysql.add_pool(
      opts |> Keyword.fetch!(:pool),
      [ host:     opts |> Keyword.get(:host, "localhost") |> to_char_list,
        port:     opts |> Keyword.get(:port, 3306),
        user:     opts |> Keyword.get(:username, "root") |> to_char_list,
        password: opts |> Keyword.get(:password, "") |> to_char_list,
        database: opts |> Keyword.fetch!(:database) |> to_char_list,
        size:     opts |> Keyword.get(:size, 5),
        encoding: opts |> Keyword.get(:encoding, :utf8)
      ]
    )
  end


  def parse_where(s) when is_binary(s), do: s
  def parse_where(w) when is_map(w), do: w |> Enum.into([]) |> parse_where
  def parse_where(w) do
    w |> Enum.map(fn
      {k, nil} ->
        "#{parse_k k} IS NUL"
      {k, v} ->
        "#{parse_k k}=#{parse_v v}"
    end) |> Enum.join " and "
  end

  def parse_where(s, w) do
    if Keyword.keyword?(w) or is_map(w) do
      r = ~r{:(\S+)}
      zip(Regex.split(r, s), Regex.scan(r, s) |> Enum.map fn [_, param] -> w[String.to_existing_atom param] end)
    else
      zip(s |> String.split("?"), w |> Enum.into [])
    end
  end

  defp zip([s], []), do: s
  defp zip([h1, h2|t1], [h3|t2]) do
    zip([Enum.join([h1, h2], parse_v(h3)) | t1], t2)
  end

  defp parse_k(s), do: ["`", "`"] |> Enum.join s |> to_string |> escape("\\") |> escape("`")
  defp parse_v(s), do: ["'", "'"] |> Enum.join s |> to_string |> escape("\\") |> escape("'")
  defp escape(s, char), do: s |> String.replace(char, "\\#{char}")


  def parse_query(q) do
    [ "SELECT",
      case {q.count, q.select} do
        {true,  _} -> " COUNT(*)"
        {false, nil} -> " *"
        {false, fields} ->
          " " <> (fields |> Enum.map(&parse_k/1) |> Enum.join ",")
      end,
      " FROM #{parse_k q.from}",
      if is_nil q.where  do "" else " WHERE #{q.where}" end,
      if is_nil q.order  do "" else
        field = q.order |> elem(0) |> parse_k
        direction = q.order |> elem(1) |> to_string |> String.upcase
        " ORDER BY #{field} #{direction}"
      end,
      if is_nil q.offset do "" else " OFFSET #{q.offset}" end,
      if is_nil q.limit  do "" else " LIMIT #{q.limit}" end
    ] |> Enum.join("")
  end


  def table_struct(repo, table) do
    case :emysql.execute(repo[:pool], "desc `#{table}`") do
      {:result_packet, _, _, results, _} ->
        results |> Enum.map fn [h|_] -> {h |> String.to_atom, nil} end
      _ -> []
    end
  end


  def select(%Q{count: true}=q) do
    [["": count]] = select(q.repo[:pool], q |> parse_query)
    count
  end

  def select(q) do
    for opts <- select(q.repo[:pool], q |> parse_query) do
      struct q.model, opts
    end
  end

  defp select(pool, sql) when is_binary(sql) do
    case :emysql.execute(pool, sql) do
      {:result_packet, _, struct, results, _} ->
        struct = struct |> Enum.map fn(s) -> s |> elem(7) |> String.to_existing_atom end
        for result <- results do
          struct |> Enum.zip(
            Enum.map result, fn
              :undefined -> nil
              # TODO
              # {:date, {_, _, _}=date} -> date
              # {:datetime, {{_, _, _}, {_, _, _}}=datetime} -> datetime
              r -> r
            end
          )
        end
      {:error_packet, _, _, _, msg} -> raise ExQ.SQLRuntimeError [msg: msg]
    end
  end


  def insert(record) do
    pool = record.__struct__.__repo__[:pool]
    pk = record.__struct__.__pk__
    values = record |> Map.to_list |> Enum.filter_map(
      fn {_, nil}                           -> false
         {k, _} when k in [:__struct__, pk] -> false
         _                                  -> true
      end,
      fn {k, {:datetime, v}} -> "#{parse_k k}=#{parse_datetime v}"
         {k, v}              -> "#{parse_k k}=#{parse_v v}"
      end) |> Enum.join ","
    sql = "INSERT INTO `#{record.__struct__.__table_name__}` SET #{values}"
    case :emysql.execute(pool, sql) do
      {:ok_packet, _, _, id, _, _, _} -> record |> struct [{pk, id}]
      {:error_packet, _, _, _, msg}   -> raise ExQ.SQLRuntimeError [msg: msg]
    end
  end


  def update(record) do
    pool = record.__struct__.__repo__[:pool]
    pk = record.__struct__.__pk__
    where = parse_where([{pk, record |> Map.get(pk)}])
    values = record |> Map.to_list |> Dict.drop([:__struct__]) |> Enum.map(fn
      {k, nil}            -> "#{parse_k k}=NULL"
      {k, {:datetime, v}} -> "#{parse_k k}=#{parse_datetime v}"
      {k, v}              -> "#{parse_k k}=#{parse_v v}"
    end) |> Enum.join ","
    sql = "UPDATE `#{record.__struct__.__table_name__}` SET #{values} WHERE #{where}"
    case :emysql.execute(pool, sql) do
      {:ok_packet, _, _, _, _, _, _}  -> record
      {:error_packet, _, _, _, msg}   -> raise ExQ.SQLRuntimeError [msg: msg]
    end
  end


  def delete([_|_]=l) do
    l |> Enum.map &delete/1
  end

  def delete(%Q{}=q) do
    case q.order || q.offset || q.limit do
      nil ->
        sql = "DELETE FROM #{parse_k q.from} WHERE #{parse_where q.where}"
        do_delete(q.repo[:pool], sql)
      _ ->
        q |> select |> delete
    end
  end

  def delete(record) do
    pool = record.__struct__.__repo__[:pool]
    pk = record.__struct__.__pk__
    where = parse_where([{pk, record |> Map.get(pk)}])
    sql = "DELETE FROM #{parse_k record.__struct__.__table_name__} WHERE #{where}"
    do_delete(pool, sql)
  end

  defp do_delete(pool, sql) do
    case :emysql.execute(pool, sql) do
      {:ok_packet, _, _, _, _, _, _}  -> :ok
      {:error_packet, _, _, _, msg}   -> raise ExQ.SQLRuntimeError [msg: msg]
    end
  end


  defp parse_datetime({{year, month, day}, {hour, minute, second}}) do
    "'~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w'"
 |> :io_lib.format([year, month, day, hour, minute, second])
 |> List.flatten |> to_string
  end
end
