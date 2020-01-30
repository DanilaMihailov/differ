defprotocol Differ.Patchable do
  alias Differ.Diffable
  @fallback_to_any true

  @type reason() :: String.t()

  @moduledoc """
  Allows to apply `diff` to a term
  """

  @doc """
  Performs operation `op` on `term`

  First argument is original term. Second is operation, 
  that get matched against functions in implementations.
  Third is a tuple, where first item should be result of the operation, 
  and second is anything else.

  Function should return tuple with `:ok` atom and tuple `{result, anything}`
  """
  # @spec perform(t(), Diffable.operation(), tuple) ::
  #         {:ok, {term, any}} | {:error, reason()} | {:conflict, any}
  # @spec perform(t(), {term, :diff, Diffable.diff()}, tuple) ::
  #         {:diff, Diffable.diff(), term, {term, :ins}}
  def perform(old_val, op, new_val)
  def perform(old_val, op, new_val, cb)

  @doc """
  Returns the opposite of operation

  If operation is not revertable, should return `{:error, reason}`

  ## Examples

      iex> Differ.diffable.revert("", {:del, "ttypo"})
      {:ok, {:ins, "ttypo"}}

      iex> Differ.diffable.revert("", {:remove, 10})
      {:error, "Operation is not revertable"}
  """
  @spec revert_op(t(), Diffable.operation()) :: {:ok, Diffable.operation()} | {:error, reason()}
  def revert_op(val, op)
end
