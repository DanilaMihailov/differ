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
    op_diff = Differ.optimize_size(diff)
    non_rev_diff = Differ.optimize_size(diff, false)

    assert new_str == Differ.patch(old_str, diff)
    assert new_str == Differ.patch(old_str, op_diff)
    assert new_str == Differ.patch(old_str, non_rev_diff)
  end

  test "string diffs are revertable" do
    old_str = "My name is Dan"
    new_str = "Hello, I'am Danila"

    diff = Differ.diff(old_str, new_str)
    op_diff = Differ.optimize_size(diff)
    non_rev_diff = Differ.optimize_size(diff, false)

    assert old_str == Differ.revert(new_str, diff)
    assert old_str == Differ.revert(new_str, op_diff)
    assert catch_error(Differ.revert(new_str, non_rev_diff)) == {:case_clause, :remove}
  end

  test "string diff without deletion are revertable" do
    old_str = "Hello, "
    new_str = "Hello, World!"

    diff = Differ.diff(old_str, new_str) |> Differ.optimize_size(false)

    assert old_str == Differ.revert(new_str, diff)
  end
end
