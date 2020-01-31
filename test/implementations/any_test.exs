defmodule Differ.AnyTest do
  use ExUnit.Case, async: true

  defmodule Some do
    defstruct val: 0
  end

  test "nils" do
    diff = Differ.diff(nil, nil)

    assert diff == nil
    assert {:ok, nil} == Differ.patch(nil, diff)
    assert {:ok, nil} == Differ.revert(nil, diff)
  end

  test "equal vals" do
    old_num = %Some{}
    new_num = %Some{}

    diff = Differ.diff(old_num, new_num)

    assert diff == nil
    assert {:ok, new_num} == Differ.patch(old_num, diff)
    assert {:ok, old_num} == Differ.revert(old_num, diff)
  end

  test "internal" do
    assert Differ.Patchable.Any.revert_op(%Some{}, {:del, 2}) == {:ok, {:del, 2}}
    assert Differ.Diffable.Any.optimize_op(%Some{}, {:del, 2}, 3) == {:ok, {:del, 2}}
  end
end
