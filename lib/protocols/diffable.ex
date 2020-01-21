defprotocol Differ.Diffable do
  @fallback_to_any true
  @moduledoc """
  Allows to compute `diff` between terms
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

  @typedoc """
  Level of optimization
  """
  @type level :: 1 | 2 | 3

  @doc """
  Returns a list of tuples that represents an edit script

  When implementing this function on a new type, you should always implement this
  ```elixir
  def diff(term, term), do: [eq: term]
  ```
  """
  @spec diff(t(), t()) :: diff
  def diff(term1, term2)

  @doc """
  Optimizes diff operation, to reduce its size

  If it returns nil, then operation can be excluded from diff
  """
  @spec optimize_op(t, operation, level) :: operation | nil
  def optimize_op(t, operation, level)
end
