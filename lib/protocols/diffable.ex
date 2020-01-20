defprotocol Differ.Diffable do
  @fallback_to_any true
  def diff(term1, term2)
end
