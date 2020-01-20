defimpl Differ.Diffable, for: BitString do
  def diff(string1, string2) do
    String.myers_difference(string1, string2)
  end

  def optimize_op(_val, {:del, val}, 3) do
    {:remove, String.length(val)}
  end

  def optimize_op(_val, {:eq, val}, level) when level > 1 do
    {:skip, String.length(val)}
  end

  def optimize_op(_val, op, _level), do: op
end
