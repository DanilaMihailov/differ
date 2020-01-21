defimpl Differ.Patchable, for: Any do
  def perform(_old_val, _op, acc), do: {:ok, acc}
  def revert_op(_val, op), do: {:ok, op}
end
