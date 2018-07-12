function on_helper(d, expr)
    syms = OrderedDict()
    res = parse_function_call!(syms, d, expr, replace_obs)
    isempty(syms) && return res
    func = Expr(:(->), Expr(:tuple, values(syms)...), res)
    Expr(:call, :(Observables.on), func, keys(syms)...)
end

function on_helper(expr)
    d = gensym()
    Expr(:(->), d, map_helper(d, expr))
end

"""
`@on(d, x)`

Apply the expression `x` to the widget `d`, replacing e.g. symbol `:s` with the corresponding `Observable` `observe(d[:s])`.
To use the value of some of `d`'s children, use `:s[]`. As soon as one of the symbols wrapped in a `\$` changes value, the expression
`x` gets executed with the updated value.
In this context, `_` refers to the whole widget. To use actual symbols, escape them with `^`, as in `^(:a)`.

## Examples

```jldoctest map!
julia> using DataStructures, InteractBase, Observables

julia> t = Widgets.Widget{:test}(OrderedDict(:a => Observable(2), :b => slider(1:100), :c => button()));
```

This prints the value of the slider as soon as the user moves it:

```jldoctest map
julia> Widgets.@on t println(\$(:b));
```

`@on(x)`

Curried version of `@on(d, x)`: anonymous function mapping `d` to `@on(d, x)`.
"""
macro on(args...)
    esc(on_helper(args...))
end
