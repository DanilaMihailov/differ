defmodule Differ do
  @moduledoc "Module that computes diff for objects"
  @moduledoc since: "0.1.0"

  @typedoc """
  Operators that define how to change data

  * `:del` - delete
  * `:ins` - insert
  * `:eq` - doesnt change
  * `:diff` - nested diff that should be applied
  * `:skip` - skip number of characters or elements
  * `:remove` - remove number of characters or elements (Non-revertable)
  """
  @type operator() :: :del | :ins | :eq | :diff | :skip | :remove

  @typedoc """
  Defines operator and value that need to be applied with operator
  ## Examples
      {:del, "s"}
      {:skip, 4}
      {"key", :ins, "s"}
  """
  @type operation() :: {operator(), any} | {any, operator(), any}

  @typedoc "Types that supported by `Differ.diff/2`"
  @type diffable() :: String.t() | number() | %{any() => diffable()} | list(diffable())

  @typedoc "List of operations need to be applied"
  @type diff() :: list(operation())

  @doc """
  Returns diff between 2 objects of same type
  """
  @spec diff(diffable(), diffable()) :: diff()
  def diff(old, new) do
    cond do
      old == new -> [eq: new]
      is_list(new) -> List.myers_difference(old, new, &diff/2)
      is_map(new) -> MapDiff.diff(old, new, &diff/2)
      is_binary(new) -> String.myers_difference(old, new)
      true -> nil
    end
  end

  @doc """
  Detects diff type

  If cannot detect type returns `:unknown`
  If diff is empty returns `:empty`

  ## Examples
      iex> Differ.get_diff_type [diff: [eq: "2", del: "2"], eq: ["1"], ins: ["3"]]
      :list
      
      iex> Differ.get_diff_type []
      :empty

      iex> Differ.get_diff_type ["some list", %{}]
      :unknown

  """
  @spec get_diff_type(diff()) :: :list | :map | :string | :unknown | :empty
  def get_diff_type(diff) do
    case diff do
      [{:skip, _num} | tail] -> get_diff_type(tail)
      [{:remove, _num} | tail] -> get_diff_type(tail)
      [{:diff, _val} | _] -> :list
      [{_key, _op, _val} | _] -> :map
      [{_op, val} | _] when is_binary(val) -> :string
      [{_op, val} | _] when is_list(val) -> :list
      [] -> :empty
      _ -> :unknown
    end
  end

  @doc """
  Applies diff and returns patched value

  ## Examples
      iex(1)> old_list = ["22", "1"]
      iex(1)> diff = Differ.diff old_list, ["2", "1", "3"]
      iex(2)> Differ.patch old_list, diff
      {:ok, ["2", "1", "3"]}
  """
  @spec patch(diffable(), diff()) :: {:ok, diffable()} | {:error, String.t()}
  def patch(obj, diff) do
    apply_diff(obj, diff, false)
  end

  @doc """
  Reverts diff and returns patched value

  ## Examples
      iex(1)> old_list = ["22", "1"]
      iex(1)> new_list = ["2", "1", "3"]
      iex(1)> diff = Differ.diff old_list, new_list 
      iex(2)> Differ.revert new_list, diff
      {:ok, ["22", "1"]}
  """
  @spec revert(diffable(), diff()) :: {:ok, diffable()} | {:error, String.t()}
  def revert(obj, diff) do
    apply_diff(obj, diff, true)
  end

  @doc """
  Removes equal data from diffs

  ## Examples
      iex> regular_diff = Differ.diff(%{"same" => "same"}, %{"same" => "same", "new" => "val"})
      [{"same", :eq, "same"}, {"new", :ins, "val"}]
      iex> Differ.optimize(regular_diff)
      [{"new", :ins, "val"}]

      iex> diff = Differ.diff("Somewhat long string with a litle change there", "Somewhat long string with a litle change here")
      [eq: "Somewhat long string with a litle change ", del: "t", eq: "here"]
      iex> Differ.optimize(diff)
      [skip: 41, del: "t", skip: 4]
  """
  @spec optimize(diff(), boolean()) :: diff()
  def optimize(diff, revertable \\ true) do
    Enum.reduce(diff, [], fn change, acc ->
      case change do
        {:diff, ndiff} ->
          acc ++ [{:diff, optimize(ndiff, revertable)}]

        {key, :diff, ndiff} ->
          acc ++ [{key, :diff, optimize(ndiff, revertable)}]

        {:eq, val} when is_list(val) ->
          acc ++ [{:skip, Enum.count(val)}]

        {:del, val} when is_list(val) and not revertable ->
          acc ++ [{:remove, Enum.count(val)}]

        {:eq, val} when is_binary(val) ->
          acc ++ [{:skip, String.length(val)}]

        {:del, val} when is_binary(val) and not revertable ->
          acc ++ [{:remove, String.length(val)}]

        {_key, :eq, _val} ->
          acc

        {key, :del, _val} when not revertable ->
          acc ++ [remove: key]

        _ ->
          acc ++ [change]
      end
    end)
  end

  defp apply_diff(obj, diff, revert) do
    type = get_diff_type(diff)

    case type do
      :unknown ->
        {:error, "Unknown diff type"}

      :empty ->
        {:ok, obj}

      :list when is_list(obj) ->
        patch(type, obj, diff, revert)

      :string when is_binary(obj) ->
        patch(type, obj, diff, revert)

      :map when is_map(obj) ->
        patch(type, obj, diff, revert)

      _ ->
        {:error, "Diff type and obj type do not match"}
    end
  end

  defp patch(:string, old_str, diff, revert) do
    result =
      Enum.reduce_while(diff, {"", 0}, fn {op, val}, {new_str, index} ->
        new_index =
          if is_binary(val) do
            String.length(val) + index
          else
            val + index
          end

        case {op, revert} do
          {:del, false} -> {:cont, {new_str, new_index}}
          {:del, true} -> {:cont, {new_str <> val, index}}
          {:eq, _} -> {:cont, {new_str <> val, new_index}}
          {:ins, false} -> {:cont, {new_str <> val, index}}
          {:ins, true} -> {:cont, {new_str, new_index}}
          {:remove, false} -> {:cont, {new_str, new_index}}
          {:remove, true} -> {:halt, {:error, "This diff is not revertable"}}
          {:skip, _} -> {:cont, {new_str <> String.slice(old_str, index, val), new_index}}
        end
      end)

    case result do
      {:error, _msg} -> result
      {str, _index} -> {:ok, str}
    end
  end

  defp patch(:list, old_list, diff, revert) do
    result =
      Enum.reduce_while(diff, {[], 0}, fn {op, val}, {new_list, index} ->
        new_index =
          if is_list(val) do
            Enum.count(val) + index
          else
            val + index
          end

        case {op, revert} do
          {:del, false} ->
            {:cont, {new_list, new_index}}

          {:del, true} ->
            {:cont, {new_list ++ val, index}}

          {:eq, _} ->
            {:cont, {new_list ++ val, new_index}}

          {:ins, false} ->
            {:cont, {new_list ++ val, index}}

          {:ins, true} ->
            {:cont, {new_list, new_index}}

          {:diff, _} ->
            patched = apply_diff(Enum.at(old_list, index), val, revert)

            case patched do
              {:ok, new_val} ->
                {:cont, {new_list ++ [new_val], index}}

              _ ->
                {:halt, patched}
            end

          {:remove, false} ->
            {:cont, {new_list, new_index}}

          {:remove, true} ->
            {:halt, {:error, "This diff is not revertable"}}

          {:skip, _} ->
            {:cont, {new_list ++ Enum.slice(old_list, index, val), new_index}}

          _ ->
            {:halt, {:error, "Unknown operation #{op} for diff of type #{:list}"}}
        end
      end)

    case result do
      {:error, _msg} -> result
      {list, _index} -> {:ok, list}
    end
  end

  defp patch(:map, old_map, diff, revert) do
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
            patched = apply_diff(Map.get(new_map, key), val, revert)

            case patched do
              {:ok, new_val} ->
                {:cont, Map.put(new_map, key, new_val)}

              {:error, _msg} ->
                {:halt, patched}
            end

          _ ->
            {:halt, {:error, "Unknown operation #{op} for diff of type #{:map}"}}
        end
      end)

    case map do
      {:error, _msg} -> map
      _ -> {:ok, map}
    end
  end
end
