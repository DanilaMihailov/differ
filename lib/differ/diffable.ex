defprotocol Differ.Diffable do
  @fallback_to_any true
  def diff(term1, term2)
end

defimpl Differ.Diffable, for: Any do
  def diff(term, term), do: [eq: term]
  def diff(_term1, _term2), do: nil
end

defimpl Differ.Diffable, for: List do
  def diff(list1, list2) do
    List.myers_difference(list1, list2, &Differ.Diffable.diff/2)
  end
end

defimpl Differ.Diffable, for: BitString do
  def diff(string1, string2) do
    String.myers_difference(string1, string2)
  end
end

defimpl Differ.Diffable, for: Map do
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
end
