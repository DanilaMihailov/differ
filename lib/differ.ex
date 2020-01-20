defmodule Differ do
  @moduledoc "Module that computes diff for objects"

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
    Differ.Diffable.diff(old, new)
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

        {:eq, val} when is_bitstring(val) ->
          acc ++ [{:skip, String.length(val)}]

        {:del, val} when is_bitstring(val) and not revertable ->
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

  defp match_res(res, old_val, acc, revert) do
    case res do
      {:ok, new_acc} ->
        {:cont, new_acc}

      {:diff, diff, old, op} ->
        diff_res = apply_diff(old, diff, revert)

        case diff_res do
          {:ok, val} ->
            new_op = Tuple.append(op, val)
            Differ.Patchable.perform(old_val, new_op, acc) |> match_res(old_val, acc, revert)

          _ ->
            {:halt, res}
        end

      _ ->
        {:halt, res}
    end
  end

  defp apply_diff(old_val, diff, revert) do
    result =
      Enum.reduce_while(diff, {old_val, 0}, fn op, acc ->
        op = if revert, do: Differ.Patchable.revert_op(old_val, op), else: op
        Differ.Patchable.perform(old_val, op, acc) |> match_res(old_val, acc, revert)
      end)

    case result do
      {:error, _msg} -> result
      {str, _other} -> {:ok, str}
    end
  end
end
