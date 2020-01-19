defmodule MapDiff do
  @moduledoc """
  Calculates diff beetwen maps
  """

  @doc """
  Calculates diff beetwen maps

  ## Examples
      
      iex> MapDiff.diff(%{test: 1}, %{test: 1})
      [eq: %{test: 1}]

      iex> MapDiff.diff(%{first_name: "Pam", last_name: "Beasly"}, %{first_name: "Pam", last_name: "Halpert"})
      [{:last_name, :ins, "Halpert"}, {:first_name, :eq, "Pam"}]
  """
  @spec diff(map(), map()) :: [{any(), atom(), map()}]
  def diff(old_map, new_map)

  def diff(map, map), do: [eq: map]

  @doc """
  Calculates diff beetwen maps using diffing function

  ## Examples

      iex> old_map = %{first_name: "Pam", last_name: "Beasly"}
      iex> new_map = %{first_name: "Pam", last_name: "Halpert"}
      iex> MapDiff.diff(old_map, new_map, &String.myers_difference/2)
      [{:last_name, :diff, [del: "Be", ins: "H", eq: "a", del: "s", eq: "l", del: "y", ins: "pert"]}, {:first_name, :eq, "Pam"}]
  """
  @spec diff(map(), map(), (Differ.diffable(), Differ.diffable() -> Differ.diff() | nil)) ::
          Differ.diff()
  def diff(old_map, new_map, differ \\ fn _old, _new -> nil end) do
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
