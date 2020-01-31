defimpl Differ.Patchable, for: BitString do
  def revert_op(_, {op, val}) do
    case op do
      :remove -> {:error, "Operation :remove is not revertable"}
      :del -> {:ok, {:ins, val}}
      :ins -> {:ok, {:del, val}}
      _ -> {:ok, {op, val}}
    end
  end

  @doc """
  Performs an operation `op` on string `str`
  """
  # def perform(str, op, acc, cb \\ &(&1))

  defp default_callback(op) do
    case op do
      {:del, _} -> ""
      {:remove, _} -> ""
      {:eq, val} -> val
      {:skip, val} -> val
      {:ins, val} -> val
      _ -> op
    end
  end

  def perform(str, op, acc, cb \\ &default_callback/1)

  def perform(_, {:del, val} = op, {new_str, index}, cb) do
    len = String.length(val)
    diff = op |> cb.() |> String.length()
    part = String.slice(new_str, index, len)

    case part do
      ^val ->
        {before, next} = String.split_at(new_str, index)
        {_, add} = String.split_at(next, len)
        {:ok, {before <> cb.(op) <> add, index + diff}}

      _ ->
        {:conflict, {op, part}}
    end
  end

  def perform(_, {:remove, len}, {new_str, index}, _cb) do
    {before, next} = String.split_at(new_str, index)
    {_, add} = String.split_at(next, len)
    {:ok, {before <> add, index}}
  end

  def perform(_, {:eq, val} = op, {new_str, index}, cb) do
    len = String.length(val)
    part = String.slice(new_str, index, len)
    new_val = cb.(op)

    case part do
      ^val -> {:ok, {new_str, index + len}}
      _ -> {:conflict, {op, part}}
    end
  end

  def perform(_, {:skip, val}, {new_str, index}, cb) do
    {:ok, {new_str, index + val}}
  end

  def perform(_, {:ins, _} = op, {new_str, index}, cb) do
    val = cb.(op)
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

  def perform(_, _, _, _), do: {:error, "Unknown operation"}
end
