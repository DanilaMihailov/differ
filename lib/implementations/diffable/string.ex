defimpl Differ.Diffable, for: BitString do
  def diff(string1, string2) do
    String.myers_difference(string1, string2)
  end

  def optimize_op(_, {:del, val} = op, 3) do
    case String.length(val) do
      1 -> op
      _ -> {:remove, String.length(val)}
    end
  end

  def optimize_op(_, {:eq, val} = op, level) when level > 1 do
    case String.length(val) do
      1 -> op
      _ -> {:skip, String.length(val)}
    end
  end

  def optimize_op(_, op, _), do: op
end
