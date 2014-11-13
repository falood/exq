defmodule ExQ.Model do
  defmacro __using__(opts) do
    repo = Keyword.get(opts, :repo, :exq_default_repo) |> ExQ.Config.repos
    table_name = Keyword.fetch! opts, :table_name
    quote do
      @repo unquote(repo)
      @table_name unquote(table_name)
      @repo[:adapter].table_struct(@repo, @table_name) |> defstruct
      @pk :id                   # TODO get PK from table describe
      @query [repo: @repo, from: @table_name, model: __MODULE__] |> Q.new

      def __pk__, do: @pk
      def __repo__, do: @repo
      def __table_name__, do: @table_name

      def select(s),    do: @query |> Q.select(s)
      def where(x),     do: @query |> Q.where(x)
      def where(x, y),  do: @query |> Q.where(x, y)
      def order(x),     do: @query |> Q.order(x)
      def order(x, y),  do: @query |> Q.order(x, y)
      def offset(x),    do: @query |> Q.offset(x)
      def limit(x),     do: @query |> Q.limit(x)
      def count,        do: @query |> Q.count
      def first,        do: @query |> Q.first
      def all,          do: @query |> Q.all

      def find(s) do
        @query |> Q.where([{@pk, s}]) |> Q.first
      end

      def find!(s) do
        find(s) || raise ExQ.RecordNotFound
      end

      def find_by(w) do
        @query |> Q.where(w) |> Q.first
      end

      def find_by!(w) do
        find_by(w) || raise ExQ.RecordNotFound
      end
    end
  end
end
