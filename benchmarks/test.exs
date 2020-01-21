old_user = %{name: "Ron Artest", teams: ["Bulls", "Pacers"]}
new_user = %{name: "Metta World Peace", teams: ["Bulls", "Pacers", "Kings", "Rockets"]}
diff = Differ.diff(old_user, new_user)

list = List.duplicate(diff, 10)
map_fun = fn d -> Differ.patch(old_user, diff) end

Benchee.run(
  %{
    "Reasonable diff" => fn -> Enum.map(list, map_fun) end
  }
)
