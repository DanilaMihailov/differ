defimpl Differ.Diffable, for: Any do
  def diff(_term1, _term2), do: nil
  def optimize_op(_val, op, _level), do: {:ok, op}
end
