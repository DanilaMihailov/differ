defprotocol Differ.Diffable do
  alias Differ.Diffable
  @fallback_to_any true
  @moduledoc """
  Allows to compute difference between objects
  """

  @typedoc """
  Diffable term
  """
  @type t() :: term()

  @typedoc """
  Operators that define how to change data

  * `:del` - delete
  * `:ins` - insert
  * `:eq` - doesnt change
  * `:diff` - nested diff that should be applied
  * `:skip` - skip number of characters or elements
  * `:remove` - remove number of characters or elements (Non-revertable)
  """
  @type operator() :: :del | :ins | :eq | :diff | :skip | :remove

  @typedoc """
  Defines operator and value that need to be applied with operator
  ## Examples
      {:del, "s"}
      {:skip, 4}
      {"key", :ins, "s"}
  """
  @type operation() :: {operator(), term} | {term, operator(), term}

  @typedoc "List of operations need to be applied"
  @type diff() :: list(operation())

  @spec diff(Diffable.t(), Diffable.t()) :: diff
  def diff(term1, term2)
end
