defmodule Differ do
  alias Differ.Diffable
  alias Differ.Patchable

  @moduledoc "Module that computes `diff` for terms"

  @doc """
  Returns diff between 2 terms of same type

  ## Examples
      iex> Differ.diff(%{key: "value"}, %{key: "value"})
      [eq: %{key: "value"}]

      iex> Differ.diff("Hello!", "Hey!")
      [eq: "He", del: "llo", ins: "y", eq: "!"]
  """
  @spec diff(Diffable.t(), Diffable.t()) :: Diffable.diff()
  def diff(old, new) do
    Diffable.diff(old, new)
  end

  @doc """
  Applies diff and returns patched value

  ## Examples
      iex(1)> old_list = ["22", "1"]
      iex(1)> diff = Differ.diff old_list, ["2", "1", "3"]
      iex(2)> Differ.patch old_list, diff
      {:ok, ["2", "1", "3"]}
  """
  @spec patch(Diffable.t(), Diffable.diff()) :: {:ok, Diffable.t()} | {:error, String.t()}
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
  @spec revert(Diffable.t(), Diffable.diff()) :: {:ok, Diffable.t()} | {:error, String.t()}
  def revert(obj, diff) do
    apply_diff(obj, diff, true)
  end

  defp optimize_op(op, level) do
    case op do
      {:remove, _val} ->
        op

      {:skip, _val} ->
        op

      {:diff, diff} ->
        new_op = optimize(diff, level)
        {:diff, new_op}

      {key, :diff, diff} ->
        new_op = optimize(diff, level)
        {key, :diff, new_op}

      {_key, :remove, _val} ->
        op

      {_key, a, _val} when is_atom(a) ->
        Diffable.optimize_op(%{}, op, level)

      {key, val} when is_atom(key) ->
        Diffable.optimize_op(val, op, level)
    end
  end

  @doc """
  Optimizes diff size

  Optimizes size by removing data that is not relevant for change.
  There is 3 levels of optimization:
    1. Safe - can have conflicts, can be reverted
    2. Safe-ish - you lose ability to get conflicts, but still can be reverted
    3. Un-safe - no conflicts and no reverting

  ## Examples
      iex> regular_diff = Differ.diff(%{"same" => "same"}, %{"same" => "same", "new" => "val"})
      [{"same", :eq, "same"}, {"new", :ins, "val"}]
      iex> Differ.optimize(regular_diff)
      [{"new", :ins, "val"}]

      iex> diff = Differ.diff("Somewhat long string with a litle change there", "Somewhat long string with a litle change here")
      [eq: "Somewhat long string with a litle change ", del: "t", eq: "here"]
      iex> Differ.optimize(diff, 2)
      [skip: 41, del: "t", skip: 4]
      iex> Differ.optimize(diff, 3)
      [skip: 41, remove: 1, skip: 4]
  """
  @spec optimize(Diffable.diff(), Diffable.level()) :: Diffable.diff()
  def optimize(diff, level \\ 1) do
    Enum.reduce(diff, [], fn operation, new_diff ->
      case optimize_op(operation, level) do
        nil -> new_diff
        opt -> new_diff ++ [opt]
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
            Patchable.perform(old_val, new_op, acc) |> match_res(old_val, acc, revert)

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
        op = if revert, do: Patchable.revert_op(old_val, op), else: op
        Patchable.perform(old_val, op, acc) |> match_res(old_val, acc, revert)
      end)

    case result do
      {:error, _msg} -> result
      {str, _other} -> {:ok, str}
    end
  end
end
