defmodule Differ.StringTest do
  use ExUnit.Case
  doctest Differ.String

  test "string diffs are patchable" do
    old_str = "My name is Dan"
    new_str = "Hello, I'am Danila"

    diff = Differ.diff(old_str, new_str)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, false)
    # invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, new_str} == Differ.patch(old_str, diff)
    assert {:ok, new_str} == Differ.patch(old_str, op_diff)
    assert {:ok, new_str} == Differ.patch(old_str, non_rev_diff)

    # assert {:error, "Unknown operation {some_random_operation, do it} for diff of type string"} ==
    #          Differ.patch(old_str, invalid_diff)
  end

  test "string diffs are revertable" do
    old_str = "My name is Dan"
    new_str = "Hello, I'am Danila"

    diff = Differ.diff(old_str, new_str)
    op_diff = Differ.optimize(diff)
    # non_rev_diff = Differ.optimize(diff, false)
    # invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, old_str} == Differ.revert(new_str, diff)
    assert {:ok, old_str} == Differ.revert(new_str, op_diff)
    # assert {:error, "This diff is not revertable"} == Differ.revert(new_str, non_rev_diff)

    # assert {:error, "Unknown operation {some_random_operation, do it} for diff of type string"} ==
    #          Differ.revert(old_str, invalid_diff)
  end

  test "string diff without deletion are revertable" do
    old_str = "Hello, "
    new_str = "Hello, World!"

    diff = Differ.diff(old_str, new_str) |> Differ.optimize(false)

    assert {:ok, old_str} == Differ.revert(new_str, diff)
  end
end
