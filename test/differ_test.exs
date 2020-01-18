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

    output = Differ.compute(old_map, new_map)

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

    diff = Differ.compute(old_str, new_str)

    assert new_str == Differ.patch(old_str, diff)

  end

  test "string diffs are revertable" do
    old_str = "My name is Dan"
    new_str = "Hello, I'am Danila"

    diff = Differ.compute(old_str, new_str)

    assert old_str == Differ.revert(new_str, diff)
  end

  # test "diffs are revertable" do
  #   old_str = "My name is Dan"
  #   new_str = "Hello, I'am Danila"
  #
  #   old_list = [old_str, 404, %{"pet" => "cat"}, [22, "22"]]
  #   new_list = [new_str, 420, %{"pet" => "dog", "another" => "cat"}, [0, "0"]]
  #
  #   old_map = %{
  #     "map" => %{
  #       "key" => old_str,
  #
  #
  #     }
  #   }
  #
  # end
end
