# Differ 

Small library for creating diffs and applying them

```elixir
iex> Differ.diff("Hello!", "Hey!")
[eq: "He", del: "llo", ins: "y", eq: "!"]

iex> Differ.patch("Hello!", [eq: "He", del: "llo", ins: "y", eq: "!"])
{:ok, "Hey!"}
```

## Installation

The package can be installed
by adding `differ` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:differ, "~> 0.1.1"}
  ]
end
```

## Documentation

Documentation can be found at [https://hexdocs.pm/differ](https://hexdocs.pm/differ).

## Usage

Simple diff of two maps

```elixir
iex> user = %{name: "John"}
iex> updated_user = Map.put(user, :age, 25)
iex> Differ.diff(user, updated_user)
[{:name, :eq, "John"}, {:age, :ins, 25}]
```

For lists and strings using `List.myers_difference/3` and `String.myers_difference/2` respectevly.
So diffs of lists and strings a excactly output of this functions
```elixir
iex> Differ.diff("Hello!", "Hey!")
[eq: "He", del: "llo", ins: "y", eq: "!"]
```

It is possible to use `Differ` with structs, you need to derive default implementation
for `Differ.Diffable` and `Differ.Patchable` protocols:
```elixir
defmodule User do
    @derive [Differ.Diffable, Differ.Patchable]
    defstruct name: "", age: 21
end
```
And now you can call `Differ.diff/2` with your structs:
```elixir
iex> Differ.diff(%User{name: "John"}, %User{name: "John Smith"})
[{:name, :diff, [eq: "John", ins: " Smith"]}, {:age, :eq, 21}]
```

As well as creating diffs, you can apply diff to a `term`. There is `Differ.patch/2` and `Differ.revert/2` for this purposes.

```elixir
iex> diff = Differ.diff("Hello!", "Hey!")
iex> Differ.patch("Hello!", diff)
{:ok, "Hey!"}
```
or revert diff
```elixir
iex> Differ.revert("Hey!", diff)
{:ok, "Hello!"}
```

For more examples look at the [docs](https://hexdocs.pm/differ/Differ.html).
