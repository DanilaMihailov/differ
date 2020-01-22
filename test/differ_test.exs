defmodule DifferTest do
  use ExUnit.Case

  # used in doc tests
  defmodule UserA do
    defstruct name: "John", age: 21
  end

  # used in doc tests
  defmodule User do
    use Differ
    defstruct name: "John", age: 21
  end

  # should be below structs definition
  doctest Differ

  test "diff structs" do
    user = %User{name: "John", age: 21}
    user_changed = %User{name: "John Smith", age: 21}

    diff = Differ.diff(user, user_changed)
    diff_op = Differ.optimize(diff)

    assert diff == [{:name, :diff, [eq: "John", ins: " Smith"]}, {:age, :eq, 21}]
    assert diff_op == [{:name, :diff, [eq: "John", ins: " Smith"]}]
    assert Differ.patch(user, diff) == {:ok, user_changed}
    assert Differ.revert(user_changed, diff) == {:ok, user}
    assert Differ.diff(%User{}, %User{}) == [eq: %User{}]
  end
end
