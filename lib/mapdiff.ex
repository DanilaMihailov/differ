defmodule MapDiff do
  @moduledoc """
  Calculates diff beetwen maps
  """

  @doc """
  Calculates diff beetwen maps

  ## Examples

      iex> old_map = %{
      ...>  "changed" => "sval", 
      ...>  "removed" => "sf", 
      ...>  "other" => 1
      ...> }
      iex> new_map = %{
      ...>  "changed" => "xval", 
      ...>  "added" => "new", 
      ...>  "other" => 1
      ...> }
      iex> MapDiff.compute(old_map, new_map)
      [{"other", :eq, 1}, {"changed", :ins, "xval"}, {"added", :ins, "new"}, {"removed", :del, "sf"}]
  """
  @spec compute(map(), map()) :: [{any(), atom(), map()}]
  def compute(old_map, new_map)

  def compute(map, map), do: [eq: map]

  @doc """
  Calculates diff beetwen maps using diffing function

  ## Examples

      iex> old_map = %{
      ...>  "changed" => "sval", 
      ...>  "removed" => "sf", 
      ...>  "other" => "same string"
      ...> }
      iex> new_map = %{
      ...>  "changed" => "xval", 
      ...>  "added" => "new", 
      ...>  "other" => "same string"
      ...> }
      iex> MapDiff.compute(old_map, new_map, &String.myers_difference/2)
      [{"other", :eq, "same string"}, {"changed", :diff, [del: "s", ins: "x", eq: "val"]}, {"added", :ins, "new"}, {"removed", :del, "sf"}]
  """
  @spec compute(map(), map(), (Differ.diffable(), Differ.diffable() -> Differ.diff() | nil)) ::
          Differ.diff()
  def compute(old_map, new_map, differ \\ fn _old, _new -> nil end) do
    old_keys = Map.keys(old_map) |> MapSet.new()
    new_keys = Map.keys(new_map) |> MapSet.new()

    del_keys = MapSet.difference(old_keys, new_keys)

    res =
      Enum.reduce(del_keys, [], fn key, ops ->
        [{key, :del, Map.fetch!(old_map, key)} | ops]
      end)

    Enum.reduce(new_map, res, fn {key, val}, ops ->
      old_val = Map.fetch(old_map, key)

      case old_val do
        :error ->
          [{key, :ins, val} | ops]

        {:ok, ^val} ->
          [{key, :eq, val} | ops]

        {:ok, old} ->
          diff = differ.(old, val)

          case diff do
            nil -> [{key, :ins, val} | ops]
            _ -> [{key, :diff, diff} | ops]
          end
      end
    end)
  end
end
