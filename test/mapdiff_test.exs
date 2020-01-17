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
    expected_output = [del: %{"removed" => "sf"}, eq: %{"other" => 1}, ins: %{"added" => "new", "changed" => "xval"}]

    assert output == expected_output
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
    expected_output = [del: %{"removed" => "sf"}, eq: %{"other" => 1}, ins: %{"added" => "new", "changed" => "xval"}]

    assert output == expected_output

  end

  test "condense simple" do
    diff = [del: %{"removed" => "sf"}, ins: %{"added" => "new", "changed" => "xval"}, eq: %{"other" => 1}]
    output = MapDiff.condense(diff)
    expected_output = [del: ["removed"], ins: %{"added" => "new", "changed" => "xval"}, eq: ["other"]]

    assert output == expected_output
  end
end
