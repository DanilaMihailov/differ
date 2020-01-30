defimpl Differ.Patchable, for: Any do
  alias Differ.Patchable

  defmacro __deriving__(module, _struct, _options) do
    quote do
      defimpl Patchable, for: unquote(module) do
        def perform(old_val, op, new_val), do: Patchable.Map.perform(old_val, op, new_val)
        def perform(old_val, op, new_val, cb), do: Patchable.Map.perform(old_val, op, new_val, cb)
        def revert_op(val, op), do: Patchable.Map.revert_op(val, op)
      end
    end
  end

  def perform(_old_val, _op, acc), do: {:ok, acc}
  def perform(_old_val, _op, acc, _cb), do: {:ok, acc}
  def revert_op(_val, op), do: {:ok, op}
end
