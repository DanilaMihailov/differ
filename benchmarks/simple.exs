old_user = %{name: "Ron Artest", teams: ["Bulls", "Pacers"], height: 201}
new_user = %{name: "Metta World Peace", teams: ["Bulls", "Pacers", "Kings", "Rockets"], height: 201, weight: 118}

diff = Differ.diff(old_user, new_user)

Benchee.run(
  %{
    "Reasonable diff" => fn diffs -> Enum.map(diffs, &(Differ.patch(old_user, &1))) end
  },
  inputs: %{
    "Level 0" => List.duplicate(diff, 10),
    "Level 1" => diff |> Differ.optimize(1) |> List.duplicate(10),
    "Level 2" => diff |> Differ.optimize(2) |> List.duplicate(10),
    "Level 3" => diff |> Differ.optimize(3) |> List.duplicate(10),
  }
)
