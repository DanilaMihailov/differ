# Differ

Small library for creating diffs and applying them

```elixir
iex> Differ.diff("Hello!", "Hey!")
[eq: "He", del: "llo", ins: "y", eq: "!"]

iex> Differ.patch("Hello!", [eq: "He", del: "llo", ins: "y", eq: "!"])
"Hey!"
```

## Installation

The package can be installed
by adding `differ` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:differ, "~> 0.1.0"}
  ]
end
```

## Usage

TODO

Documentation can be found at [https://hexdocs.pm/differ](https://hexdocs.pm/differ).

