function map_helper(d, expr)
    syms = OrderedDict()
    res = parse_function_call!(syms, d, expr, replace_obs)
    isempty(syms) && return res
    func = Expr(:(->), Expr(:tuple, values(syms)...), res)
    Expr(:call, :map, func, keys(syms)...)
end

"""
`@map(d, x)`

Apply the expression `x` to the widget `d`, replacing e.g. symbol `:s` with the corresponding `Observable` `observe(d[:s])`.
To use the value of some of `d`'s children, use `:s[]`. Use `\$(:s)` if you want the output to update automatically as soon
as the value of `observe(d[:s])` changes.
In this context, `_` refers to the whole widget. To use actual symbols, escape them with `^`, as in `^(:a)`.

## Examples

```jldoctest map
julia> using DataStructures, InteractBase, Observables

julia> t = Widgets.Widget{:test}(OrderedDict(:a => Observable(2), :b => slider(1:100), :c => button()));
```

This updates as soon as `observe(t[:a])` or `observe(t[:b])` change:

```jldoctest map
julia> Widgets.@map t \$(:a) + \$(:b)
Observables.Observable{Int64}("ob_31", 52, Any[])
```

whereas this only updates when button `:c` is pressed:

```jldoctest map
julia> Widgets.@map t (\$(:c); :a[] + :b[])
Observables.Observable{Int64}("ob_33", 52, Any[])
```
"""
macro map(d, expr)
    esc(map_helper(d, expr))
end

replace_obs(s) = s

replace_obs(d, x...) = Expr(:call, :(Widgets.observe), d, x...)
