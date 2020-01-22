defmodule DifferTest do
  use ExUnit.Case

  # used in doc tests
  defmodule User do
    @derive [Differ.Diffable, Differ.Patchable]
    defstruct name: "John", age: 21
  end

  # should be below structs used in tests
  doctest Differ

  # used only in this test
  defmodule Smth do
    @derive [Differ.Diffable, Differ.Patchable]
    defstruct val: nil
  end

  defmodule Obj do
    @derive [Differ.Diffable, Differ.Patchable]
    defstruct name: "John", age: 21, parents: [], smth: %Smth{}
  end

  test "diff structs" do
    user = %Obj{name: "John", age: 21, parents: [%Obj{name: 1}, %Obj{name: 2}]}

    user_changed = %Obj{
      name: "John Smith",
      age: 21,
      parents: [%Obj{name: 4, smth: %Smth{val: [%{lol: 1}]}}, %Obj{name: 2}]
    }

    diff = Differ.diff(user, user_changed)
    diff_op = Differ.optimize(diff)
    max_op = Differ.optimize(diff, 3)

    assert Differ.patch(user, diff) == {:ok, user_changed}
    assert Differ.patch(user, diff_op) == {:ok, user_changed}
    assert Differ.patch(user, max_op) == {:ok, user_changed}

    assert Differ.revert(user_changed, diff) == {:ok, user}

    assert Differ.diff(%Obj{}, %Obj{}) == [eq: %Obj{}]
  end
end
