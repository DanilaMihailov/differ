old_user = %{name: "Ron Artest", teams: ["Bulls", "Pacers"], height: 201}
new_user = %{name: "Metta World Peace", teams: ["Bulls", "Pacers", "Kings", "Rockets"], height: 201, weight: 118}

diff = Differ.diff(old_user, new_user)
l0 = List.duplicate(diff, 10)
l1 = diff |> Differ.optimize(1) |> List.duplicate(10)
l2 = diff |> Differ.optimize(2) |> List.duplicate(10)
l3 = diff |> Differ.optimize(3) |> List.duplicate(10)

Benchee.run(
  %{
    "Patch level 0" => fn -> Enum.map(l0, &(Differ.patch(old_user, &1))) end,
    "Patch level 1" => fn -> Enum.map(l1, &(Differ.patch(old_user, &1))) end,
    "Patch level 2" => fn -> Enum.map(l2, &(Differ.patch(old_user, &1))) end,
    "Patch level 3" => fn -> Enum.map(l3, &(Differ.patch(old_user, &1))) end
  }
)
