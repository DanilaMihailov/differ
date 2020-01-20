defprotocol Differ.Patchable do
  @fallback_to_any true
  @doc """
  Performs operation `op` on `term`

  First argument is original term. Second is operation, that get matched against functions in implementations. Third is a tuple, where first item should be result of the operation, and second is anything else.

  Function should return tuple with `:ok` atom and tuple {result, anything}
  """
  @spec perform(term, tuple, tuple) :: {:ok, {term, any}}
  @spec perform(term, {term, :diff, list(term)}, tuple) :: {:diff, list(term), term, {term, :ins}}
  def perform(old_val, op, new_val)
  def revert_op(val, op)
end

defimpl Differ.Patchable, for: Any do
  def perform(_old_val, _op, acc), do: {:ok, acc}
  def revert_op(_val, op), do: op
end

defimpl Differ.Patchable, for: BitString do
  def revert_op(_val, {op, val}) do
    new_op = case op do
      :del -> :ins
      :ins -> :del
      _ -> op
    end
    {new_op, val}
  end

  def perform(_old_str, {:del, val}, {new_str, index}) do
    len = String.length(val)
    part = String.slice(new_str, index, len)
    case part do
      ^val -> 
        {before, next} = String.split_at(new_str, index)
        {_, add} = String.split_at(next, len)
        {:ok, {before <> add, index}}
      _ -> 
        {:error, "Conflict #{val} != #{part}"}
    end
  end

  def perform(_old_str, {:eq, val}, {new_str, index}) do
    {:ok, {new_str, index + String.length(val)}}
  end

  def perform(_old_str, {:skip, val}, {new_str, index}) do
    {:ok, {new_str, index + val}}
  end

  def perform(_old_str, {:ins, val}, {new_str, index}) do
    new_str = 
      cond do
        index == 0 -> val <> new_str 
        index == String.length(new_str) -> new_str <> val
        true ->
          {before, next} = String.split_at(new_str, index)
          before <> val <> next

      end
    {:ok, {new_str, index + String.length(val)}}
  end
end

defimpl Differ.Patchable, for: Map do
  def revert_op(_val, {key, op, val}) do
    new_op = case op do
      :del -> :ins
      :ins -> :del
      _ -> op
    end
    {key, new_op, val}
  end

  def perform(_old_map, {:eq, _val}, {new_map, _}), do: {:ok, {new_map, nil}}

  def perform(_old_map, {key, :del, _val}, {new_map, _}) do
    {:ok, {Map.delete(new_map, key), nil}}
  end

  def perform(_old_map, {_key, :eq, _val}, {new_map, _}) do
    {:ok, {new_map, nil}}
  end

  def perform(_old_map, {key, :ins, val}, {new_map, _}) do
    {:ok, {Map.put(new_map, key, val), nil}}
  end

  def perform(old_map, {key, :diff, diff}, _acc) do
    {:diff, diff, Map.get(old_map, key), {key, :ins}}
  end
end

defimpl Differ.Patchable, for: List do
  def revert_op(_val, {op, val}) do
    new_op = case op do
      :del -> :ins
      :ins -> :del
      _ -> op
    end
    {new_op, val}
  end

  # FIXME: duplicates value not working right
  def perform(_old_list, {:del, val}, {new_list, index}) do
    {:ok, {new_list -- val, index}}
  end

  def perform(_old_list, {:eq, val}, {new_list, index}) do
    {:ok, {new_list, Enum.count(val) + index}}
  end

  def perform(_old_list, {:skip, val}, {new_list, index}) do
    {:ok, {new_list, index + val}}
  end

  def perform(_old_list, {:ins, val}, {new_list, index}) do
    {new_list, _} = Enum.reduce(List.wrap(val), {new_list, index}, fn v, {l, i} ->
      {List.insert_at(l, i, v), i + 1}
    end)
    {:ok, {new_list, index + Enum.count(val)}}
  end

  def perform(_old_list, {:replace, val}, {new_list, index}) do
    {:ok, {List.replace_at(new_list, index, val), index + 1}}
  end

  def perform(old_list, {:diff, diff}, {_, index}) do
    {:diff, diff, Enum.at(old_list, index), {:replace}}
  end

end
