defmodule Differ do
  alias Differ.Diffable
  alias Differ.Patchable

  @moduledoc """
  Module that computes `diff` for terms

  # Using with structs

  It is possible to use `Differ` with structs, you need to derive default implementation
  for `Differ.Diffable` and `Differ.Patchable` protocols:
  ```elixir
  defmodule User do
    @derive [Differ.Diffable, Differ.Patchable]
    defstruct name: "", age: 21
  end
  ```
  And now you can call `Differ.diff/2` with your structs:
      iex> Differ.diff(%User{name: "John"}, %User{name: "John Smith"})
      [{:name, :diff, [eq: "John", ins: " Smith"]}, {:age, :eq, 21}]

  """

  @doc """
  Returns diff between 2 terms that implement `Differ.Diffable` protocol

  Diff here is *edit script*, that should be compatible with `List.myers_difference/3`

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
      iex> old_list = ["22", "1"]
      iex> diff = Differ.diff(old_list, ["2", "1", "3"])
      iex> Differ.patch(old_list, diff)
      {:ok, ["2", "1", "3"]}
  """
  @spec patch(Patchable.t(), Diffable.diff()) :: {:ok, Patchable.t()} | {:error, String.t()}
  def patch(obj, diff) do
    apply_diff(obj, diff, false)
  end

  @spec patch(Patchable.t(), Diffable.diff()) :: Patchable.t()
  def patch!(obj, diff) do
    case patch(obj, diff) do
      {:ok, val} -> val
    end
  end

  @doc """
  Reverts diff and returns patched value

  ## Examples
      iex> old_list = ["22", "1"]
      iex> new_list = ["2", "1", "3"]
      iex> diff = Differ.diff(old_list, new_list)
      iex> Differ.revert(new_list, diff)
      {:ok, ["22", "1"]}
  """
  @spec revert(Patchable.t(), Diffable.diff()) :: {:ok, Patchable.t()} | {:error, String.t()}
  def revert(obj, diff) do
    apply_diff(obj, diff, true)
  end

  @spec revert(Patchable.t(), Diffable.diff()) :: Patchable.t()
  def revert!(obj, diff) do
    case revert(obj, diff) do
      {:ok, val} -> val
    end
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

      iex> diff = Differ.diff("Somewhat long string with a litle change athere", "Somewhat long string with a litle change here")
      [eq: "Somewhat long string with a litle change ", del: "at", eq: "here"]
      iex> Differ.optimize(diff, 2)
      [skip: 41, del: "at", skip: 4]
      iex> Differ.optimize(diff, 3)
      [skip: 41, remove: 2, skip: 4]
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
            {:halt, diff_res}
        end

      _ ->
        {:halt, res}
    end
  end

  defp apply_diff(nil, _, _), do: {:ok, nil}
  defp apply_diff(v, nil, _), do: {:ok, v}

  defp apply_diff(old_val, diff, revert) do
    result =
      Enum.reduce_while(diff, {old_val, 0}, fn op, acc ->
        op = if revert, do: Patchable.revert_op(old_val, op), else: {:ok, op}

        case op do
          {:ok, op} ->
            Patchable.perform(old_val, op, acc) |> match_res(old_val, acc, revert)

          _ ->
            {:halt, op}
        end
      end)

    case result do
      {:error, _} -> result
      {:conflict, _} -> result
      {val, _} -> {:ok, val}
    end
  end
end
