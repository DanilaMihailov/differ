defmodule DifferTest do
  use ExUnit.Case
  doctest Differ

  test "complex diff" do
    old_map = %{
      "changed" => "sval",
      "removed" => "sf",
      "same" => 1,
      "nested" => %{
        "list" => [1, 2],
        "map" => %{
          "same3" => 1,
          "another list" => [0, 1]
        }
      }
    }

    new_map = %{
      "changed" => "xval",
      "added" => "new",
      "same" => 1,
      "nested" => %{
        "list" => [0, 2, 3],
        "map" => %{
          "same3" => 1,
          "another list" => [1],
          "lol" => "querty"
        }
      }
    }

    output = Differ.diff(old_map, new_map)

    expected_output = [
      {"same", :eq, 1},
      {"nested", :diff,
       [
         {"map", :diff,
          [
            {"same3", :eq, 1},
            {"lol", :ins, "querty"},
            {"another list", :diff, [del: [0], eq: [1]]}
          ]},
         {"list", :diff, [del: [1], ins: [0], eq: [2], ins: [3]]}
       ]},
      {"changed", :diff, [del: "s", ins: "x", eq: "val"]},
      {"added", :ins, "new"},
      {"removed", :del, "sf"}
    ]

    assert expected_output == output
  end

  test "string diffs are patchable" do
    old_str = "My name is Dan"
    new_str = "Hello, I'am Danila"

    diff = Differ.diff(old_str, new_str)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, false)
    invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, new_str} == Differ.patch(old_str, diff)
    assert {:ok, new_str} == Differ.patch(old_str, op_diff)
    assert {:ok, new_str} == Differ.patch(old_str, non_rev_diff)

    assert {:error, "Unknown operation {some_random_operation, do it} for diff of type string"} ==
             Differ.patch(old_str, invalid_diff)
  end

  test "string diffs are revertable" do
    old_str = "My name is Dan"
    new_str = "Hello, I'am Danila"

    diff = Differ.diff(old_str, new_str)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, false)
    invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, old_str} == Differ.revert(new_str, diff)
    assert {:ok, old_str} == Differ.revert(new_str, op_diff)
    assert {:error, "This diff is not revertable"} == Differ.revert(new_str, non_rev_diff)

    assert {:error, "Unknown operation {some_random_operation, do it} for diff of type string"} ==
             Differ.revert(old_str, invalid_diff)
  end

  test "string diff without deletion are revertable" do
    old_str = "Hello, "
    new_str = "Hello, World!"

    diff = Differ.diff(old_str, new_str) |> Differ.optimize(false)

    assert {:ok, old_str} == Differ.revert(new_str, diff)
  end
end
