defprotocol Differ.Patchable do
  alias Differ.Diffable
  @fallback_to_any true

  @moduledoc """
  Applies `diff` to a term
  """

  @doc """
  Performs operation `op` on `term`

  First argument is original term. Second is operation, that get matched against functions in implementations.
  Third is a tuple, where first item should be result of the operation, and second is anything else.

  Function should return tuple with `:ok` atom and tuple {result, anything}
  """
  @spec perform(t(), Diffable.operation(), tuple) :: {:ok, {term, any}}
  @spec perform(t(), {term, :diff, Diffable.diff()}, tuple) ::
          {:diff, Diffable.diff(), term, {term, :ins}}
  def perform(old_val, op, new_val)
  def revert_op(val, op)

  # TODO: add catch all function in implementation and return {:error, reason}?
  # TODO: check revert_op when reverting non-revertable should throw?
end
