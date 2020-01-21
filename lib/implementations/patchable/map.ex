defimpl Differ.Patchable, for: Map do
  def revert_op(_val, {key, op, val}) do
    case op do
      :remove -> {:error, "Operation :remove is not revertable"}
      :del -> {:ok, {key, :ins, val}}
      :ins -> {:ok, {key, :del, val}}
      _ -> {:ok, {key, op, val}}
    end
  end

  def perform(_old_map, {:eq, _val}, {new_map, _}), do: {:ok, {new_map, nil}}

  def perform(_old_map, {key, :del, _val}, {new_map, _}) do
    {:ok, {Map.delete(new_map, key), nil}}
  end

  def perform(_old_map, {_key, :eq, _val}, {new_map, _}) do
    {:ok, {new_map, nil}}
  end

  def perform(_old_map, {key, :ins, val}, {new_map, _}) do
    {:ok, {Map.put(new_map, key, val), nil}}
  end

  def perform(old_map, {key, :diff, diff}, _acc) do
    {:diff, diff, Map.get(old_map, key), {key, :ins}}
  end

  def perform(_, _, _), do: {:error, "Unknown operation"}
end
