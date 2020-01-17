defmodule MapDiff do
  @moduledoc """
  Calculates diff beetwen maps
  """

  @doc """
  Calculates diff beetwen maps

  ## Examples

      iex> old_map = %{
      ...>  "changed" => "sval", 
      ...>  "removed" => "sf", 
      ...>  "other" => 1
      ...> }
      iex> new_map = %{
      ...>  "changed" => "xval", 
      ...>  "added" => "new", 
      ...>  "other" => 1
      ...> }
      iex> MapDiff.compute(old_map, new_map)
      [del: %{"removed" => "sf"}, eq: %{"other" => 1}, ins: %{"added" => "new", "changed" => "xval"}]
  """
  @spec compute(map(), map()) :: [{atom(), map()}]
  def compute(old_map, new_map)

  def compute(map, map), do: [eq: map]

  def compute(old_map, new_map, differ \\ fn (_old, new) -> [eq: new] end) when is_map(old_map) and is_map(new_map) do
    old_keys = Map.keys(old_map) |> MapSet.new()
    new_keys = Map.keys(new_map) |> MapSet.new()

    del_keys = MapSet.difference(old_keys, new_keys)
    add_keys = MapSet.difference(new_keys, old_keys)
    same_keys = MapSet.intersection(old_keys, new_keys)

    res = []

    res = if MapSet.size(del_keys) > 0, do: [{:del, Map.take(old_map, del_keys)} | res], else: res

    new_changes = Enum.reduce(MapSet.union(same_keys, add_keys), [], fn (key, acc) ->
      old_val = Map.fetch(old_map, key)
      new_val = Map.fetch(new_map, key)
      {:ok, value} = new_val

      case old_val do
        :error -> Keyword.update(acc, :ins, %{key => value}, &(Map.merge(&1, %{key => value})))
        ^new_val -> Keyword.update(acc, :eq, %{key => value}, &(Map.merge(&1, %{key => value})))
        _ ->
          diff = differ.(elem(old_val, 1), value)
          case diff do
            [eq: val] -> Keyword.update(acc, :ins, %{key => val}, &(Map.merge(&1, %{key => val})))
            _ -> Keyword.update(acc, :diff, %{key => diff}, &(Map.merge(&1, %{key => diff})))
          end
      end
    end)

    res = new_changes ++ res

    Enum.reverse res
  end

  @doc """
  Condenses diff by removing values from `:del` and `:eq` keys

  ## Examples
      iex> MapDiff.condense([del: %{"removed" => "sf"}, ins: %{"added" => "new", "changed" => "xval"}, eq: %{"other" => 1}])
      [del: ["removed"], ins: %{"added" => "new", "changed" => "xval"}, eq: ["other"]]

  """
  @spec condense([{atom(), map()}]) :: [{atom(), map() | list(String.t())}]
  def condense(diff) do
    Enum.map(diff, fn {key, val} -> 
      case key do
        :ins -> {key, val}
        _ -> {key, Map.keys(val)}
      end
    end)
  end

end
