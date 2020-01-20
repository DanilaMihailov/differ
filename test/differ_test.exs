defmodule DifferTest do
  use ExUnit.Case
  doctest Differ

  test "complex diff" do
    old_map = %{
      "changed" => "sval",
      "removed" => "sf",
      "same" => 1,
      "nested" => %{
        "maps" => %{"key" => "val", "key2" => "val2"},
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
        "maps" => %{"key" => "val", "key2" => "val2"},
        "list" => [0, 2, 3],
        "map" => %{
          "same3" => 1,
          "another list" => [1],
          "lol" => "querty"
        }
      }
    }

    output = Differ.diff(old_map, new_map)
    op_diff = Differ.optimize(output, true)

    assert {:ok, new_map} == Differ.patch(old_map, output)
    assert {:ok, new_map} == Differ.patch(old_map, op_diff)
    assert {:ok, old_map} == Differ.revert(new_map, output)

    expected_output = [
      {"same", :eq, 1},
      {"nested", :diff,
       [
         {"maps", :eq, %{"key" => "val", "key2" => "val2"}},
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
end
