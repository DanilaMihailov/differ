defmodule Differ.String do
  def diff(old_string, new_string) when is_bitstring(old_string) and is_bitstring(new_string) do
    String.myers_difference(old_string, new_string)
  end

  def string_diff?(diff) when is_bitstring(diff) do
    case diff do
      [{:skip, _num} | tail] -> string_diff?(tail)
      [{:remove, _num} | tail] -> string_diff?(tail)
      [{op, val} | _] when is_atom(op) and is_bitstring(val) -> true
      _ -> false
    end
  end

  def patch(old_string, diff) do
    patch(old_string, diff, false)
  end

  def revert(old_string, diff) do
    patch(old_string, diff, true)
  end

  defp patch(old_string, diff, revert) do
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
          {:skip, _} -> {:cont, {new_str <> String.slice(old_string, index, val), new_index}}
          _ -> {:halt, {:error, "Unknown operation {#{op}, #{val}} for diff of type #{:string}"}}
        end
      end)

    case result do
      {:error, _msg} -> result
      {str, _index} -> {:ok, str}
    end
  end
end
