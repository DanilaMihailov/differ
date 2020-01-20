defimpl Differ.Diffable, for: Any do
  def diff(term, term), do: [eq: term]
  def diff(_term1, _term2), do: nil
end
