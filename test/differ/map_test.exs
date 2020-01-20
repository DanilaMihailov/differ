defmodule Differ.MapTest do
  use ExUnit.Case
  # doctest Differ.Map

  test "simple" do
    old_map = %{
      "changed" => "sval",
      "removed" => "sf",
      "other" => 1
    }

    new_map = %{
      "changed" => "xval",
      "added" => "new",
      "other" => 1
    }

    output = Differ.diff(old_map, new_map)

    expected_output = [
      {"other", :eq, 1},
      {"changed", :diff, [del: "s", ins: "x", eq: "val"]},
      {"added", :ins, "new"},
      {"removed", :del, "sf"}
    ]

    assert expected_output == output
  end

  test "nested maps" do
    old_map = %{
      "changed" => "sval",
      "removed" => "sf",
      "other" => 1,
      "nested" => %{
        "same" => 0,
        "del this" => 1,
        "update this" => "old str"
      }
    }

    new_map = %{
      "changed" => "xval",
      "added" => "new",
      "other" => 1,
      "nested" => %{
        "same" => 0,
        "update this" => "new str",
        "new" => 9
      }
    }

    output = Differ.diff(old_map, new_map)

    expected_output = [
      {"other", :eq, 1},
      {"nested", :diff,
       [
         {"update this", :diff, [del: "old", ins: "new", eq: " str"]},
         {"same", :eq, 0},
         {"new", :ins, 9},
         {"del this", :del, 1}
       ]},
      {"changed", :diff, [del: "s", ins: "x", eq: "val"]},
      {"added", :ins, "new"},
      {"removed", :del, "sf"}
    ]

    assert output == expected_output
  end
end
