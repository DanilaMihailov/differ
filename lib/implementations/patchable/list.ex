defimpl Differ.Patchable, for: List do
  def revert_op(_, {op, val}) do
    case op do
      :remove -> {:error, "Operation :remove is not revertable"}
      :del -> {:ok, {:ins, val}}
      :ins -> {:ok, {:del, val}}
      _ -> {:ok, {op, val}}
    end
  end

  defp default_callback(op) do
    case op do
      {:del, _} -> ""
      {:remove, _} -> ""
      {:eq, val} -> val
      {:skip, val} -> val
      {:ins, val} -> val
    end
  end

  def perform(str, op, acc, cb \\ &default_callback/1)

  def perform(_, {:del, val} = op, {new_list, index}, _cb) do
    len = Enum.count(val)
    part = Enum.slice(new_list, index, len)

    case part do
      ^val -> perform(new_list, {:remove, len}, {new_list, index})
      _ -> {:conflict, {op, part}}
    end
  end

  def perform(_, {:remove, len}, {nlist, index}, _cb) do
    {before, next} = Enum.split(nlist, index)
    {_, add} = Enum.split(next, len)

    {:ok, {before ++ add, index}}
  end

  def perform(_, {:eq, val} = op, {new_list, index}, _cb) do
    len = Enum.count(val)
    part = Enum.slice(new_list, index, len)

    case part do
      ^val -> {:ok, {new_list, len + index}}
      _ -> {:conflict, {op, part}}
    end
  end

  def perform(_, {:skip, val}, {new_list, index}, _cb) do
    {:ok, {new_list, index + val}}
  end

  def perform(_, {:ins, val}, {new_list, index}, _cb) do
    {new_list, _} =
      Enum.reduce(List.wrap(val), {new_list, index}, fn v, {l, i} ->
        {List.insert_at(l, i, v), i + 1}
      end)

    {:ok, {new_list, index + Enum.count(val)}}
  end

  def perform(_, {:replace, val}, {new_list, index}, _cb) do
    {:ok, {List.replace_at(new_list, index, val), index + 1}}
  end

  def perform(old_list, {:diff, diff}, {_, index}, _cb) do
    {:diff, diff, Enum.at(old_list, index), {:replace}}
  end

  def perform(_, _, _, _cb), do: {:error, "Unknown operation"}
end
