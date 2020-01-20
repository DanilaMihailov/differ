defmodule Differ do
  alias Differ.Diffable
  alias Differ.Patchable

  @moduledoc "Module that computes diff for objects"

  @doc """
  Returns diff between 2 objects of same type

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
  @spec optimize(Diffable.diff(), boolean()) :: Diffable.diff()
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
