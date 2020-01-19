defmodule Differ.List do
  def diff(old_list, new_list) when is_list(old_list) and is_list(new_list) do
    List.myers_difference(old_list, new_list)
  end

  def diff(old_list, new_list, differ)
      when is_list(old_list) and is_list(new_list) and is_function(differ) do
    List.myers_difference(old_list, new_list, differ)
  end

  def list_diff?(diff) when is_list(diff) do
    case diff do
      [{:skip, _num} | tail] -> list_diff?(tail)
      [{:remove, _num} | tail] -> list_diff?(tail)
      [{:diff, _val} | _] -> true
      [{op, val} | _] when is_atom(op) and is_list(val) -> true
      _ -> false
    end
  end

  @doc false
  defp nested_noop(_diff),
    do: {:error, "Nested diffs are not supported, use Differ.List.patch/3 function"}

  @doc false
  defp nested_noop_revert(_diff),
    do: {:error, "Nested diffs are not supported, use Differ.List.revert/3 function"}

  def patch(old_list, diff) do
    patch(old_list, diff, false, &nested_noop/1)
  end

  def patch(old_list, diff, nested_patcher) do
    patch(old_list, diff, false, nested_patcher)
  end

  def revert(old_list, diff) do
    patch(old_list, diff, true, &nested_noop_revert/1)
  end

  def revert(old_list, diff, nested_patcher) do
    patch(old_list, diff, true, nested_patcher)
  end

  defp patch(old_list, diff, revert, nested_patcher) do
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
            patched = nested_patcher.(Enum.at(old_list, index), val, revert)

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
            {:halt, {:error, "Unknown operation {#{op}, #{val}} for diff of type #{:list}"}}
        end
      end)

    case result do
      {:error, _msg} -> result
      {list, _index} -> {:ok, list}
    end
  end
end
