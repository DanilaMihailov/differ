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
      del: %{"removed" => "sf"}, 
      eq: %{"same" => 1}, 
      diff: %{
        "changed" => [del: "s", ins: "x", eq: "val"], 
        "nested" => [
          diff: %{
            "list" => [diff: [ins: 0], eq: [2], ins: [3]], 
            "map" => [
              ins: %{"lol" => "querty"}, 
              diff: %{
                "another list" => [diff: [ins: 1], del: [1]]
              }
            ]
          }
        ]
      }, 
      ins: %{"added" => "new"}]

    assert output == expected_output
  end
end
