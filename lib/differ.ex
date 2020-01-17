defmodule Differ do
  @moduledoc "Module that computes diff for objects"
  @moduledoc since: "0.1.0"

  @typedoc """
  Operators that define how to change data

  * `:del` - delete
  * `:ins` - insert
  * `:eq` - doesnt change
  * `:inc` - increment (only aplicable for `number()`)
  """
  @type operator() :: :del | :ins | :eq | :inc

  @typedoc """
  Defines operator and value that need to be applied with operator
  ## Examples
      {:del, "s"}

  """
  @type operation() :: {operator(), any}

  @typedoc """
  Defines path to value and operations needed to be done to this value

  ## Examples
  If we had user with name "Cara" and name was changed to "Sara", we could represent it like this
      {"user.name", [del: "C", ins: "S", eq: "ara"]}
  """
  @type change() :: {String.t(), [operation]}

  @typedoc "Types that supported by `Differ.compute/2`"
  @type diffable() :: String.t() | number() | %{any() => diffable()} | list(diffable())




  @doc """
  Computes diff between 2 objects of same type

  ## Examples
      
  For primitives returns just `[operation]`
      iex> Differ.compute("Sara Connor", "Cara Common")
      [del: "S", ins: "C", eq: "ara Co", del: "nn", ins: "mm", eq: "o", del: "r", ins: "n"]

      iex> Differ.compute(1, 3)
      [inc: 2]

      iex> Differ.compute(nil, 3)
      [ins: 3]

  For complext types returns `[change]`
      iex> Differ.compute(%{"simple" => "sval"}, %{"simple" => "xval"})
      [{"simple", [del: "s", ins: "x", eq: "val"]}]

      iex> Differ.compute(%{"key1" => "val1", "key2" => ["1", "2"], "same" => "same"}, %{"key1" => "val2new", "key2" => ["2", "3"], "same" => "same"})
      [{"key1", [eq: "val", del: "1", ins: "2new"]}, {"key2", [del: ["1"], eq: ["2"], ins: ["3"]]}, {"same", [eq: "same"]}]

      iex> Differ.compute(%{"nested" => %{"n1" => "1"}}, %{"nested" => %{"n1" => "2"}})
      [{"nested.n1", [del: "1", ins: "2"]}]

      iex> Differ.compute([1, 2, 3], [1, 3])
      [{"0", [eq: 1]}, {"1", [del: 2]}, {"2", [eq: 3]}]
      
  """
  @spec compute(diffable(), diffable()) :: list(change())
  def compute(old, new)

  def compute(old, new) when is_binary(old) and is_binary(new) do
    old |> calc(new)
  end

  def compute(old, new) when is_integer(old) and is_integer(new) do
    old |> calc(new)
  end

  def compute(nil, new) when is_integer(new), do: calc(nil, new)

  @spec compute(diffable(), diffable()) :: list(change())
  def compute(old, new) do
    old |> calc(new) |> unwrap()
  end

  defp calc(old, new) when is_binary(old) and is_binary(new) do
    String.myers_difference(old, new)
  end

  defp calc(nil, new) when is_binary(new) do
    calc("", new)
  end

  defp calc(old, new) when is_integer(old) and is_integer(new) and old == new, do: [eq: old]
  defp calc(old, new) when is_integer(old) and is_integer(new), do: [inc: new - old]
  defp calc(nil, new) when is_integer(new), do: [ins: new]

  defp calc(old, new) when is_list(old) and is_list(new) do
    # old_len = List.length(old)
    # new_len = List.length(new)
    # len_diff = old_len - new_len

    # new
    #   |> Enum.with_index()
    #   |> Enum.map fn {val, index} ->
    #       {:key, Integer.to_string(index), Enum.at(old, index) |> calc(val)}
    #     end

    List.myers_difference(old, new, &calc/2)
  end

  defp calc(nil, new) when is_list(new) do
    calc([], new)
  end

  defp calc(old, new) when is_map(old) and is_map(new) do
    Enum.map(new, fn {key, val} ->
      {:key, key, Map.get(old, key) |> calc(val)}
    end)
  end

  defp unwrap(val, path \\ "")

  defp unwrap({:key, key, val}, path) do
    IO.puts("unwrap #{key} -> #{path}")
    IO.inspect(val)
    unwrap(val, "#{path}.#{key}" |> String.trim("."))
  end

  defp unwrap(obj = {_key, _val}, path) do
    case path do
      "" -> obj
      _ -> {path, obj}
    end
  end

  defp unwrap(val, path) when is_list(val) do
    IO.puts("unwrap list -> #{path}")
    IO.inspect(val)
    cond do
      Keyword.keyword?(val) -> {path, val}
      true -> Enum.map(val, fn el -> unwrap(el, path) end) |> List.flatten()
    end
    
  end
end
