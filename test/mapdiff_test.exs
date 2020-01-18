defmodule MapDiffTest do
  use ExUnit.Case
  doctest MapDiff

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
    output = MapDiff.compute(old_map, new_map)
    expected_output = [{"other", :eq, 1}, {"changed", :ins, "xval"}, {"added", :ins, "new"}, {"removed", :del, "sf"}]

    assert expected_output == output
  end

  defp differ(old, new) do
    cond do
      is_map(new) -> MapDiff.compute(old, new, &differ/2)
      is_binary(new) -> String.myers_difference(old, new)
      true -> [eq: new]
    end
  end

  test "nested maps" do
    old_map = %{
      "changed" => "sval", 
      "removed" => "sf", 
      "other" => 1,
      "nested" => %{
        "same" => 0,
        "del this" => 1,
        "update this" => "old str",
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
    output = MapDiff.compute(old_map, new_map, &differ/2)
    expected_output = [{"other", :eq, 1}, {"nested", :diff, [{"update this", :diff, [del: "old", ins: "new", eq: " str"]}, {"same", :eq, 0}, {"new", :ins, 9}, {"del this", :del, 1}]}, {"changed", :diff, [del: "s", ins: "x", eq: "val"]}, {"added", :ins, "new"}, {"removed", :del, "sf"}]

    assert output == expected_output

  end
end
