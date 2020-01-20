defimpl Differ.Diffable, for: Map do
  def optimize_op(_val, {_key, :eq, _}, _), do: nil

  def optimize_op(_val, op, _level), do: op

  def diff(map, map), do: [eq: map]

  def diff(old_map, new_map) do
    del_keys = Map.keys(old_map) -- Map.keys(new_map)

    res =
      Enum.reduce(del_keys, [], fn key, ops ->
        [{key, :del, Map.fetch!(old_map, key)} | ops]
      end)

    Enum.reduce(new_map, res, fn {key, val}, ops ->
      old_val = Map.fetch(old_map, key)

      case old_val do
        :error ->
          [{key, :ins, val} | ops]

        {:ok, ^val} ->
          [{key, :eq, val} | ops]

        {:ok, old} ->
          diff = Differ.Diffable.diff(old, val)

          case diff do
            nil -> [{key, :ins, val} | ops]
            _ -> [{key, :diff, diff} | ops]
          end
      end
    end)
  end

  def optimize_op(_, operation), do: operation
end
