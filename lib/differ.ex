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
      iex(1)> old_list = ["22", "1"]
      iex(1)> new_list = ["2", "1", "3"]
      iex(1)> diff = Differ.compute old_list, new_list 
      iex(2)> Differ.revert new_list, diff
      ["22", "1"]
  """
  @spec revert(diffable(), diff()) :: diffable()
  def revert(obj, diff) do
    type = get_diff_type(diff)

    case type do
      :unknown -> nil
      _ -> revert(type, obj, diff)
    end
  end

  @doc """
  Removes equal data from diffs

  ## Examples
      iex> regular_diff = Differ.compute(%{"same" => "same"}, %{"same" => "same", "new" => "val"})
      [{"same", :eq, "same"}, {"new", :ins, "val"}]
      iex> Differ.optimize_size(regular_diff)
      [{"new", :ins, "val"}]

      iex> diff = Differ.compute("Somewhat long string with a litle change there", "Somewhat long string with a litle change here")
      [eq: "Somewhat long string with a litle change ", del: "t", eq: "here"]
      iex> Differ.optimize_size(diff)
      [skip: 41, del: "t", skip: 4]
  """
  @spec optimize_size(diff(), boolean()) :: diff()
  def optimize_size(diff, revertable \\ true) do
    Enum.reduce(diff, [], fn change, acc ->
      case change do
        {:diff, ndiff} ->
          acc ++ [{:diff, optimize_size(ndiff, revertable)}]

        {key, :diff, ndiff} ->
          acc ++ [{key, :diff, optimize_size(ndiff, revertable)}]

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

  defp patch(:string, old_str, diff) do
    {str, _} =
      Enum.reduce(diff, {"", 0}, fn {op, val}, {new_str, index} ->
        new_index =
          if is_binary(val) do
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
    {list, _} =
      Enum.reduce(diff, {[], 0}, fn {op, val}, {new_list, index} ->
        new_index =
          if is_list(val) do
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

  defp revert(:string, old_string, diff) do
    {str, _} =
      Enum.reduce(diff, {"", 0}, fn {op, val}, {new_str, index} ->
        new_index =
          if is_binary(val) do
            String.length(val) + index
          else
            val + index
          end

        case op do
          :ins -> {new_str, new_index}
          :eq -> {new_str <> val, new_index}
          :del -> {new_str <> val, index}
          # :remove -> {new_str, new_index}
          :skip -> {new_str <> String.slice(old_string, index, val), new_index}
        end
      end)

    str
  end

  defp revert(:list, old_list, diff) do
    {list, _} =
      Enum.reduce(diff, {[], 0}, fn {op, val}, {new_list, index} ->
        new_index =
          if is_list(val) do
            Enum.count(val) + index
          else
            val + index
          end

        case op do
          :ins -> {new_list, new_index}
          :eq -> {new_list ++ val, new_index}
          :del -> {new_list ++ val, index}
          :diff -> {new_list ++ [revert(Enum.at(old_list, index), val)], index}
          # :remove -> {new_list, new_index}
          :skip -> {new_list ++ Enum.slice(old_list, index, val), new_index}
        end
      end)

    list
  end

  defp revert(:map, old_map, diff) do
    Enum.reduce(diff, old_map, fn {key, op, val}, new_map ->
      case op do
        :ins -> Map.delete(new_map, key)
        :eq -> new_map
        :del -> Map.put(new_map, key, val)
        :diff -> Map.put(new_map, key, revert(Map.get(new_map, key), val))
      end
    end)
  end
end
