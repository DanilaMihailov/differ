defmodule Differ.StringTest do
  use ExUnit.Case

  test "string diffs are patchable" do
    old_str = "My name is Dan"
    new_str = "Hello, I'am Danila"

    diff = Differ.diff(old_str, new_str)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, 3)
    invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, new_str} == Differ.patch(old_str, diff)
    assert {:ok, new_str} == Differ.patch(old_str, op_diff)
    assert {:ok, new_str} == Differ.patch(old_str, non_rev_diff)

    assert {:error, "Unknown operation"} ==
             Differ.patch(old_str, invalid_diff)
  end

  test "string diffs are revertable" do
    old_str = "My name is Dan"
    new_str = "Hello, I'am Danila"

    diff = Differ.diff(old_str, new_str)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, 3)
    invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, old_str} == Differ.revert(new_str, diff)
    assert {:ok, old_str} == Differ.revert(new_str, op_diff)
    assert {:error, "Operation :remove is not revertable"} == Differ.revert(new_str, non_rev_diff)

    assert {:error, "Unknown operation"} ==
             Differ.revert(old_str, invalid_diff)
  end

  test "string diff without deletion are always revertable" do
    old_str = "Hello, "
    new_str = "Hello, World!"

    diff = Differ.diff(old_str, new_str) |> Differ.optimize(3)

    assert {:ok, old_str} == Differ.revert(new_str, diff)
  end
end
