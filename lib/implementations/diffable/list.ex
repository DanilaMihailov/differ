defimpl Differ.Diffable, for: List do
  def diff(list1, list2) do
    List.myers_difference(list1, list2, &Differ.Diffable.diff/2)
  end

  def optimize_op(_val, {:del, val}, 3) do
    {:remove, Enum.count(val)}
  end

  def optimize_op(_val, {:eq, val}, level) when level > 1 do
    {:skip, Enum.count(val)}
  end

  def optimize_op(_val, op, _level), do: op

end
