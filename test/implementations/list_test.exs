defmodule Differ.ListTest do
  use ExUnit.Case, async: true

  test "empty lists" do
    diff = Differ.diff([], [])

    assert diff == []
    assert {:ok, []} == Differ.patch([], diff)
    assert {:ok, []} == Differ.revert([], diff)
  end

  test "equal lists" do
    old_list = [1, %{key: 1}, "1", {1, 1}]
    new_list = [1, %{key: 1}, "1", {1, 1}]

    diff = Differ.diff(old_list, new_list)

    assert diff == [eq: old_list]
    assert {:ok, new_list} == Differ.patch(old_list, diff)
    assert {:ok, old_list} == Differ.revert(old_list, diff)
  end

  test "list diffs are patchable" do
    old_list = [1, 2, 2, 3]
    new_list = [3, 2, 2, 1, 0]

    diff = Differ.diff(old_list, new_list)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, 3)
    invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, new_list} == Differ.patch(old_list, diff)
    assert {:ok, new_list} == Differ.patch(old_list, op_diff)
    assert {:ok, new_list} == Differ.patch(old_list, non_rev_diff)

    assert {:error, "Unknown operation"} ==
             Differ.patch(old_list, invalid_diff)
  end

  test "list diffs are revertable" do
    old_list = [1, 2, 2, 3]
    new_list = [3, 2, 2, 1, 0]

    diff = Differ.diff(old_list, new_list)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, 3)
    invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, old_list} == Differ.revert(new_list, diff)
    assert {:ok, old_list} == Differ.revert(new_list, op_diff)

    assert {:error, "Operation :remove is not revertable"} ==
             Differ.revert(new_list, non_rev_diff)

    assert {:error, "Unknown operation"} ==
             Differ.revert(old_list, invalid_diff)
  end

  test "list diff without deletion are always revertable" do
    old_list = [1, 2, 2, 3]
    new_list = [1, 2, 2, 3, 4, 5]

    diff = Differ.diff(old_list, new_list) |> Differ.optimize(3)

    assert {:ok, old_list} == Differ.revert(new_list, diff)
  end
end
