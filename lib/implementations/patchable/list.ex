defimpl Differ.Patchable, for: List do
  def revert_op(_val, {op, val}) do
    case op do
      :remove -> {:error, "Operation :remove is not revertable"}
      :del -> {:ok, {:ins, val}}
      :ins -> {:ok, {:del, val}}
      _ -> {:ok, {op, val}}
    end
  end

  # FIXME: duplicates value not working right
  def perform(_old_list, {:del, val}, {new_list, index}) do
    {:ok, {new_list -- val, index}}
  end

  def perform(_old_list, {:eq, val}, {new_list, index}) do
    {:ok, {new_list, Enum.count(val) + index}}
  end

  def perform(_old_list, {:skip, val}, {new_list, index}) do
    {:ok, {new_list, index + val}}
  end

  def perform(_old_list, {:ins, val}, {new_list, index}) do
    {new_list, _} =
      Enum.reduce(List.wrap(val), {new_list, index}, fn v, {l, i} ->
        {List.insert_at(l, i, v), i + 1}
      end)

    {:ok, {new_list, index + Enum.count(val)}}
  end

  def perform(_old_list, {:replace, val}, {new_list, index}) do
    {:ok, {List.replace_at(new_list, index, val), index + 1}}
  end

  def perform(old_list, {:diff, diff}, {_, index}) do
    {:diff, diff, Enum.at(old_list, index), {:replace}}
  end

  def perform(_, _, _), do: {:error, "Unknown operation"}
end
