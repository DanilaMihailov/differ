defimpl Differ.Patchable, for: Map do
  def revert_op(_, {key, op, val}) do
    case op do
      :remove -> {:error, "Operation :remove is not revertable"}
      :del -> {:ok, {key, :ins, val}}
      :ins -> {:ok, {key, :del, val}}
      _ -> {:ok, {key, op, val}}
    end
  end

  def revert_op(_, op), do: {:ok, op}

  def perform(_, {:eq, _} = op, {new_map, _}), do: {:ok, {new_map, op}}

  def perform(_, {key, :del, _} = op, {new_map, prev_op}) do
    case prev_op do
      {^key, :ins, _} -> {:ok, {new_map, op}}
      _ -> {:ok, {Map.delete(new_map, key), op}}
    end
  end

  def perform(_, {_, :eq, _} = op, {new_map, _}) do
    {:ok, {new_map, op}}
  end

  def perform(_, {key, :ins, val} = op, {new_map, _}) do
    {:ok, {Map.put(new_map, key, val), op}}
  end

  def perform(_, {key, :diff, diff}, {new_map, _}) do
    {:diff, diff, Map.get(new_map, key), {key, :ins}}
  end

  def perform(_, _, _), do: {:error, "Unknown operation"}
end
