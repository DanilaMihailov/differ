defmodule Differ do
  @moduledoc "Module that computes diff for objects"
  @moduledoc since: "0.1.0"

  @typedoc """
  Operators that define how to change data

  * `:del` - delete
  * `:ins` - insert
  * `:eq` - doesnt change
  * `:diff` - nested diff that should be applied
  """
  @type operator() :: :del | :ins | :eq | :diff

  @typedoc """
  Defines operator and value that need to be applied with operator
  ## Examples
      {:del, "s"}
      {"key", :ins, "s"}
  """
  @type operation() :: {operator(), any} | {any, operator(), any}

  @typedoc "Types that supported by `Differ.compute/2`"
  @type diffable() :: String.t() | number() | %{any() => diffable()} | list(diffable())

  @typedoc "List of operations need to be applied"
  @type diff() :: list(operation())

  @doc """
  Computes diff between 2 objects of same type
  """
  @spec compute(diffable(), diffable()) :: diff()
  def compute(old, new) do
    cond do
      old == new -> [eq: new]
      is_list(new) -> List.myers_difference(old, new, &compute/2)
      is_map(new) -> MapDiff.compute(old, new, &compute/2)
      is_binary(new) -> String.myers_difference(old, new)
      true -> nil
    end
  end

  @doc """
  Detects diff type

  If cannot detect type, or diff is empty returns `:unknown`

  ## Examples
      iex> Differ.get_diff_type [diff: [eq: "2", del: "2"], eq: ["1"], ins: ["3"]]
      :list
      
      iex> Differ.get_diff_type []
      :unknown

  """
  @spec get_diff_type(diff()) :: :list | :map | :string | :unknown
  def get_diff_type(diff) do
    case diff do
      [{:skip, _num} | tail] -> get_diff_type(tail)
      [{:remove, _num} | tail] -> get_diff_type(tail)
      [{:diff, _val} | _] -> :list
      [{_key, _op, _val} | _] -> :map
      [{_op, val} | _] when is_binary(val) -> :string
      [{_op, val} | _] when is_list(val) -> :list
      _ -> :unknown
    end
  end

  @doc """
  Applies diff and returns patched value

  ## Examples
      iex(1)> old_list = ["22", "1"]
      iex(1)> diff = Differ.compute old_list, ["2", "1", "3"]
      iex(2)> Differ.patch old_list, diff
      ["2", "1", "3"]
  """
  @spec patch(diffable(), diff()) :: diffable() | nil
  def patch(obj, diff) do
    # TODO: compare obj type with diff type
    type = get_diff_type(diff)

    case type do
      :unknown -> nil
      _ -> patch(type, obj, diff)
    end
  end

  @doc """
  Reverts diff and returns patched value

  ## Examples
      iex(1)> diff = Differ.compute ["22", "1"], ["2", "1", "3"]
      iex(2)> Differ.revert diff
      ["22", "1"]
  """
  @spec revert(diff()) :: diffable()
  def revert(diff) do
    type = get_diff_type(diff)

    case type do
      :unknown -> nil
      _ -> revert(type, diff)
    end
  end

  defp patch(:string, old_str, diff) do
    {str, _} = Enum.reduce(diff, {"", 0}, fn {op, val}, {new_str, index} ->
      new_index = if is_binary(val) do
        String.length(val) + index
      else
        val + index
      end

      case op do
        :del -> {new_str, new_index}
        :eq -> {new_str <> val, new_index}
        :ins -> {new_str <> val, index}

        :remove -> {new_str, new_index}
        :skip -> {new_str <> String.slice(old_str, index, val), new_index}
      end
    end)

    str
  end

  defp patch(:list, old_list, diff) do
    {list, _} = Enum.reduce(diff, {[], 0}, fn {op, val}, {new_list, index} ->
      new_index = if is_list(val) do
        Enum.count(val) + index
      else
        val + index
      end

      case op do
        :del -> {new_list, new_index}
        :eq -> {new_list ++ val, new_index}
        :ins -> {new_list ++ val, index}
        :diff -> {new_list ++ [patch(Enum.at(old_list, index), val)], index}

        :remove -> {new_list, new_index}
        :skip -> {new_list ++ Enum.slice(old_list, index, val), new_index}
      end
    end)

    list
  end

  defp patch(:map, old_map, diff) do
    Enum.reduce(diff, old_map, fn {key, op, val}, new_map ->
      case op do
        :del -> Map.delete(new_map, key)
        :eq -> new_map
        :ins -> Map.put(new_map, key, val)
        :diff -> Map.put(new_map, key, patch(Map.get(new_map, key), val))
      end
    end)
  end

  defp revert(:string, diff) do
    Enum.reduce(diff, "", fn {op, val}, new_str ->
      case op do
        :ins -> new_str
        _ -> new_str <> val
      end
    end)
  end

  defp revert(:list, diff) do
    Enum.reduce(diff, [], fn {op, val}, new_list ->
      case op do
        :ins -> new_list
        :diff -> new_list ++ [revert(val)]
        _ -> new_list ++ val
      end
    end)
  end

  defp revert(:map, diff) do
    Enum.reduce(diff, %{}, fn {key, op, val}, new_map ->
      case op do
        :ins -> new_map
        :diff -> Map.put(new_map, key, revert(val))
        _ -> Map.put(new_map, key, val)
      end
    end)
  end
end
