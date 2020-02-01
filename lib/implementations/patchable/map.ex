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

  def explain(map, op, {res, index}, cb) do
    new_acc = case op do
      {key, :diff, diff} -> 
        nres = Differ.explain(Map.get(map, key), diff, cb)
        {res <> nres, index}
      _ -> {res <> cb.(op), index}
    end
    {:ok, new_acc}
  end

  def perform(_, {:eq, _} = op, {new_map, _}), do: {:ok, {new_map, op}}

  def perform(_, {key, :del, val} = op, {new_map, prev_op}) do
    case prev_op do
      {^key, :ins, _} ->
        {:ok, {new_map, op}}

      _ ->
        old_val = Map.get(new_map, key)

        case old_val do
          ^val -> {:ok, {Map.delete(new_map, key), op}}
          _ -> {:conflict, {op, old_val}}
        end
    end
  end

  def perform(_, {key, :eq, val} = op, {new_map, _}) do
    old_val = Map.get(new_map, key)

    case old_val do
      ^val -> {:ok, {new_map, op}}
      _ -> {:conflict, {op, old_val}}
    end
  end

  def perform(_, {key, :ins, val} = op, {new_map, _}) do
    {:ok, {Map.put(new_map, key, val), op}}
  end

  def perform(_, {key, :diff, diff}, {new_map, _}) do
    {:diff, diff, Map.get(new_map, key), {key, :ins}}
  end

  def perform(_, _, _), do: {:error, "Unknown operation"}
end
