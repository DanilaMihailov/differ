defmodule Differ.Map do
  @moduledoc """
  Calculates diff beetwen maps
  """

  @doc """
  Calculates diff beetwen maps

  ## Examples
      
      iex> Differ.Map.diff(%{test: 1}, %{test: 1})
      [eq: %{test: 1}]

      iex> Differ.Map.diff(%{first_name: "Pam", last_name: "Beasly"}, %{first_name: "Pam", last_name: "Halpert"})
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
      iex> Differ.Map.diff(old_map, new_map, &String.myers_difference/2)
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

  @doc """
  Checks if given diff is for a map
  """
  @spec map_diff?(Differ.diff()) :: boolean()
  def map_diff?(diff) when is_list(diff) do
    case diff do
      [{:remove, _num_or_key} | tail] -> map_diff?(tail)
      [{_key, op, _val} | _] when is_atom(op) -> true
      [eq: val] when is_map(val) -> true
      _ -> false
    end
  end

  @doc false
  defp nested_noop(_diff),
    do: {:error, "Nested diffs are not supported, use Differ.Map.patch/3 function"}

  @doc false
  defp nested_noop_revert(_diff),
    do: {:error, "Nested diffs are not supported, use Differ.Map.revert/3 function"}

  def patch(old_map = %{}, diff) do
    patch(old_map, diff, false, &nested_noop/1)
  end

  def patch(old_map = %{}, diff, nested_patcher) do
    patch(old_map, diff, false, nested_patcher)
  end

  def revert(old_map = %{}, diff) do
    patch(old_map, diff, true, &nested_noop_revert/1)
  end

  def revert(old_map = %{}, diff, nested_patcher) do
    patch(old_map, diff, true, nested_patcher)
  end

  defp patch(old_map, diff, revert, nested_patcher) do
    map =
      Enum.reduce_while(diff, old_map, fn {key, op, val}, new_map ->
        case {op, revert} do
          {:del, false} ->
            {:cont, Map.delete(new_map, key)}

          {:del, true} ->
            {:cont, Map.put(new_map, key, val)}

          {:eq, _} ->
            {:cont, new_map}

          {:ins, false} ->
            {:cont, Map.put(new_map, key, val)}

          {:ins, true} ->
            {:cont, Map.delete(new_map, key)}

          {:diff, _} ->
            patched = nested_patcher.(Map.get(new_map, key), val, revert)

            case patched do
              {:ok, new_val} ->
                {:cont, Map.put(new_map, key, new_val)}

              {:error, _msg} ->
                {:halt, patched}
            end

          _ ->
            {:halt,
             {:error, "Unknown operation {#{key}, #{op}, #{val}} for diff of type #{:map}"}}
        end
      end)

    case map do
      {:error, _msg} -> map
      _ -> {:ok, map}
    end
  end
end

H
