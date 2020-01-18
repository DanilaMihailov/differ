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
      iex(1)> diff = Differ.compute ["22", "1"], ["2", "1", "3"]
      iex(2)> Differ.patch diff
      ["2", "1", "3"]
  """
  @spec patch(diff()) :: diffable()
  def patch(diff) do
    type = get_diff_type(diff)
    case type do
      :unknown -> nil
      _ -> patch(type, diff)
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

  defp patch(:string, diff) do
    Enum.reduce(diff, "", fn ({op, val}, new_str) ->
      case op do
        :del -> new_str
        _ -> new_str <> val
      end
    end)
  end

  defp patch(:list, diff) do
    Enum.reduce(diff, [], fn ({op, val}, new_list) ->
      case op do
        :del -> new_list
        :diff -> new_list ++ [patch(val)]
        _ -> new_list ++ val
      end
    end)
  end

  defp patch(:map, diff) do
    Enum.reduce(diff, %{}, fn ({key, op, val}, new_map) ->
      case op do
        :del -> new_map
        :diff -> Map.put(new_map, key, patch(val))
        _ -> Map.put(new_map, key, val)
      end
    end)
  end

  defp revert(:string, diff) do
    Enum.reduce(diff, "", fn ({op, val}, new_str) ->
      case op do
        :ins -> new_str
        _ -> new_str <> val
      end
    end)
  end

  defp revert(:list, diff) do
    Enum.reduce(diff, [], fn ({op, val}, new_list) ->
      case op do
        :ins -> new_list
        :diff -> new_list ++ [revert(val)]
        _ -> new_list ++ val
      end
    end)
  end

  defp revert(:map, diff) do
    Enum.reduce(diff, %{}, fn ({key, op, val}, new_map) ->
      case op do
        :ins -> new_map
        :diff -> Map.put(new_map, key, revert(val))
        _ -> Map.put(new_map, key, val)
      end
    end)
  end

end
