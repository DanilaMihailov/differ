defimpl Differ.Diffable, for: BitString do
  def diff(string1, string2) do
    String.myers_difference(string1, string2)
  end
end
