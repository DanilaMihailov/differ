defimpl Differ.Diffable, for: Any do
  defmacro __deriving__(module, _struct, options) do
    quote do
      defimpl Differ.Diffable, for: unquote(module) do
        def optimize_op(val, op, level), do: Differ.Diffable.Map.optimize_op(val, op, level)

        def diff(s, s), do: [eq: s]

        def diff(old, new) do
          opts = unquote(options)
          diff = Differ.Diffable.Map.diff(Map.from_struct(old), Map.from_struct(new))
          case Keyword.fetch(opts, :skip) do
            {:ok, skip} ->
              skip = MapSet.new(skip)
              Enum.reject(diff, fn op -> 
                case op do
                  {key, _, _} -> MapSet.member?(skip, key)
                end
              end)
            _ -> diff
          end
        end
      end
    end
  end

  def diff(_term1, _term2), do: nil
  def optimize_op(_val, op, _level), do: {:ok, op}
end
