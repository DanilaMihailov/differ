defmodule Differ.AnyTest do
  use ExUnit.Case

  defmodule Some do
    defstruct val: 0
  end

  test "nils" do
    diff = Differ.diff(nil, nil)

    assert diff == nil
    assert {:ok, nil} == Differ.patch(nil, diff)
    assert {:ok, nil} == Differ.revert(nil, diff)
  end

  test "equal numbers" do
    old_num = 123
    new_num = 123

    diff = Differ.diff(old_num, new_num)

    assert diff == nil
    assert {:ok, new_num} == Differ.patch(old_num, diff)
    assert {:ok, old_num} == Differ.revert(old_num, diff)
  end
end
