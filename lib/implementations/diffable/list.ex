defimpl Differ.Diffable, for: List do
  def diff(list1, list2) do
    List.myers_difference(list1, list2, &Differ.Diffable.diff/2)
  end
end
