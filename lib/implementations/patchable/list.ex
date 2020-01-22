defimpl Differ.Patchable, for: List do
  def revert_op(_, {op, val}) do
    case op do
      :remove -> {:error, "Operation :remove is not revertable"}
      :del -> {:ok, {:ins, val}}
      :ins -> {:ok, {:del, val}}
      _ -> {:ok, {op, val}}
    end
  end

  # TODO: add conflict checks
  def perform(_, {:del, val}, {new_list, index}) do
    perform(new_list, {:remove, Enum.count(val)}, {new_list, index})
  end

  def perform(_, {:remove, len}, {nlist, index}) do
    {before, next} = Enum.split(nlist, index)
    {_, add} = Enum.split(next, len)

    {:ok, {before ++ add, index}}
  end

  def perform(_, {:eq, val}, {new_list, index}) do
    {:ok, {new_list, Enum.count(val) + index}}
  end

  def perform(_, {:skip, val}, {new_list, index}) do
    {:ok, {new_list, index + val}}
  end

  def perform(_, {:ins, val}, {new_list, index}) do
    {new_list, _} =
      Enum.reduce(List.wrap(val), {new_list, index}, fn v, {l, i} ->
        {List.insert_at(l, i, v), i + 1}
      end)

    {:ok, {new_list, index + Enum.count(val)}}
  end

  def perform(_, {:replace, val}, {new_list, index}) do
    {:ok, {List.replace_at(new_list, index, val), index + 1}}
  end

  def perform(old_list, {:diff, diff}, {_, index}) do
    {:diff, diff, Enum.at(old_list, index), {:replace}}
  end

  def perform(_, _, _), do: {:error, "Unknown operation"}
end
