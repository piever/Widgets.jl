function map_helper(d, expr)
    syms = OrderedDict()
    res = parse_function_call!(syms, d, expr, replace_obs)
    isempty(syms) && return res
    func = Expr(:(->), Expr(:tuple, values(syms)...), res)
    Expr(:call, :map, func, keys(syms)...)
end

function map_helper(expr)
    d = gensym()
    Expr(:(->), d, map_helper(d, expr))
end

"""
`@map(d, x)`

Apply the expression `x` to the widget `d`, replacing e.g. symbol `:s` with the corresponding `Observable` `observe(d[:s])`.
To use the value of some of `d`'s components, use `:s[]`. Use `\$(:s)` if you want the output to update automatically as soon
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

`@map(x)`

Curried version of `@map(d, x)`: anonymous function mapping `d` to `@map(d, x)`.
"""
macro map(args...)
    Base.depwarn("Widgets.@map is deprecated", "map")
    esc(map_helper(args...))
end

function map!_helper(d, target, expr)
    syms = OrderedDict()
    res = parse_function_call!(syms, d, expr, replace_obs)
    func = Expr(:(->), Expr(:tuple, values(syms)...), res)
    Expr(:call, :map!, func, parse_function_call(d, target, replace_obs), keys(syms)...)
end

function map!_helper(target, expr)
    d = gensym()
    Expr(:(->), d, map!_helper(d, target, expr))
end

"""
`@map!(d, target, x)`

In the expression `x` to the widget `d`, replace e.g. symbol `:s` with the corresponding `Observable` `observe(d[:s])`.
To use the value of some of `d`'s components, use `:s[]`. As soon as one of the symbols wrapped in a `\$` changes value, the observable
target gets updated with the value of that expression. If no symbol is wrapped in a `\$`, nothing happens.
In this context, `_` refers to the whole widget. To use actual symbols, escape them with `^`, as in `^(:a)`.

## Examples

```jldoctest map!
julia> using DataStructures, InteractBase, Observables

julia> t = Widgets.Widget{:test}(OrderedDict(:a => Observable(2), :b => slider(1:100), :c => button()));
```

This updates `t[:a]` as soon as the user moves the slider:

```jldoctest map
julia> Widgets.@map! t :a \$(:b);
```

`@map!(target, x)`

Curried version of `@map!(d, target, x)`: anonymous function mapping `d` to `@map(d, target, x)`.
"""
macro map!(args...)
    Base.depwarn("Widgets.@map! is deprecated", "map!")
    esc(map!_helper(args...))
end

replace_obs(s) = s

replace_obs(d, x...) = Expr(:call, :(Widgets.observe), d, x...)
