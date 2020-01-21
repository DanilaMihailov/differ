defmodule Differ.MapTest do
  use ExUnit.Case

  setup do
    old_map = %{
      "changed" => "sval",
      "removed" => "sf",
      "other" => 1,
      "nested" => %{
        "same" => 0,
        "del this" => 1,
        "update this" => "old map"
      },
      akey: %{
        bkey: %{
          ckey: %{
            dkey: %{
              ekey: [1, 2, 3]
            }
          }
        }
      }
    }

    new_map = %{
      "changed" => "xval",
      "added" => "new",
      "other" => 1,
      "nested" => %{
        "same" => 0,
        "update this" => "new map",
        "new" => 9
      },
      akey: %{
        bkey: %{
          ckey: %{
            dkey: %{
              ekey: [1]
            }
          }
        }
      }
    }

    [old: old_map, new: new_map]
  end

  test "empty maps" do
    diff = Differ.diff(%{}, %{})

    assert diff == []
    assert {:ok, %{}} == Differ.patch(%{}, diff)
    assert {:ok, %{}} == Differ.revert(%{}, diff)
  end

  test "equal maps" do
    old_map = %{key: "val"}
    new_map = %{key: "val"}

    diff = Differ.diff(old_map, new_map)

    assert diff == [eq: %{key: "val"}]
    assert {:ok, new_map} == Differ.patch(old_map, diff)
    assert {:ok, old_map} == Differ.revert(old_map, diff)
  end

  test "map diffs are patchable", context do
    old_map = context[:old]
    new_map = context[:new]

    diff = Differ.diff(old_map, new_map)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, 3)
    invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, new_map} == Differ.patch(old_map, diff)
    assert {:ok, new_map} == Differ.patch(old_map, op_diff)
    assert {:ok, new_map} == Differ.patch(old_map, non_rev_diff)

    assert {:error, "Unknown operation"} ==
             Differ.patch(old_map, invalid_diff)
  end

  test "map diffs are revertable", context do
    old_map = context[:old]
    new_map = context[:new]

    diff = Differ.diff(old_map, new_map)
    op_diff = Differ.optimize(diff)
    non_rev_diff = Differ.optimize(diff, 3)
    invalid_diff = [{:some_random_operation, "do it"} | diff]

    assert {:ok, old_map} == Differ.revert(new_map, diff)
    assert {:ok, old_map} == Differ.revert(new_map, op_diff)

    assert {:error, "Operation :remove is not revertable"} ==
             Differ.revert(new_map, non_rev_diff)

    assert {:error, "Unknown operation"} ==
             Differ.revert(new_map, invalid_diff)
  end

  test "map diff without deletion are always revertable" do
    old_map = %{k1: "val", k2: "val"}
    new_map = %{k1: "val", k2: "val", k3: "val"}

    diff = Differ.diff(old_map, new_map) |> Differ.optimize(3)

    assert {:ok, old_map} == Differ.revert(new_map, diff)
  end
end
