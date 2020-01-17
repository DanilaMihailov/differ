defmodule DifferTest do
  use ExUnit.Case
  # doctest Differ

  test "greets the world" do
    old_map = %{
      "changed" => "sval", 
      "removed" => "sf", 
      "same" => 1,
      "nested" => %{
        "list" => [1, 2],
        "map" => %{
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
          "another list" => [1],
          "lol" => "querty"
        }
      }
    }
    output = Differ.calc(old_map, new_map)
    expected_output = [
      diff: [{"changed", [del: "s", ins: "x", eq: "val"]}], 
      del: "removed", 
      ins: %{"added" => "new val"}, 
      eq: "other", 
      eq: "another", 
      del: "sdel"
    ]

    assert output == expected_output
  end
end
