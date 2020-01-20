defimpl Differ.Patchable, for: BitString do
  def revert_op(_val, {op, val}) do
    new_op =
      case op do
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

  def perform(_old_str, {:remove, val}, {new_str, index}) do
    len = val

    {before, next} = String.split_at(new_str, index)
    {_, add} = String.split_at(next, len)
    {:ok, {before <> add, index}}
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
        index == 0 ->
          val <> new_str

        index == String.length(new_str) ->
          new_str <> val

        true ->
          {before, next} = String.split_at(new_str, index)
          before <> val <> next
      end

    {:ok, {new_str, index + String.length(val)}}
  end
end

