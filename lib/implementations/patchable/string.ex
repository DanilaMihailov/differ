defimpl Differ.Patchable, for: BitString do
  def revert_op(_, {op, val}) do
    case op do
      :remove -> {:error, "Operation :remove is not revertable"}
      :del -> {:ok, {:ins, val}}
      :ins -> {:ok, {:del, val}}
      _ -> {:ok, {op, val}}
    end
  end

  def explain(str, op, {res, index}, cb) do
    new_acc =
      case op do
        {:skip, n} -> {res <> cb.({:eq, String.slice(str, index, n)}), index + n}
        {:eq, val} -> {res <> cb.(op), index + String.length(val)}
        {:ins, val} -> {res <> cb.(op), index + String.length(val)}
        _ -> {res <> cb.(op), index}
      end

    {:ok, new_acc}
  end

  def perform(_, {:del, val} = op, {new_str, index}) do
    len = String.length(val)
    part = String.slice(new_str, index, len)

    case part do
      ^val ->
        {before, next} = String.split_at(new_str, index)
        {_, add} = String.split_at(next, len)
        {:ok, {before <> add, index}}

      _ ->
        {:conflict, {op, part}}
    end
  end

  def perform(_, {:remove, len}, {new_str, index}) do
    {before, next} = String.split_at(new_str, index)
    {_, add} = String.split_at(next, len)
    {:ok, {before <> add, index}}
  end

  def perform(_, {:eq, val} = op, {new_str, index}) do
    len = String.length(val)
    part = String.slice(new_str, index, len)

    case part do
      ^val -> {:ok, {new_str, index + len}}
      _ -> {:conflict, {op, part}}
    end
  end

  def perform(_, {:skip, val}, {new_str, index}) do
    {:ok, {new_str, index + val}}
  end

  def perform(_, {:ins, val}, {new_str, index}) do
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

  def perform(_, _, _), do: {:error, "Unknown operation"}
end
