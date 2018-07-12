"""
`@layout(x)`

Returns a function, that takes as argument a widget `d` and replaces e.g. symbol `:s` with the corresponding
subwidget `d[:s]`.
In this context, `_` refers to the whole widget. To use actual symbols, escape them with `^`, as in `^(:a)`.

## Examples

```jldoctest map
julia> using DataStructures, InteractBase, CSSUtil

julia> f = Widgets.@layout hbox(:b, CSSUtil.hskip(1em), :c);

julia> t = Widgets.Widget{:test}(OrderedDict(:b => slider(1:100), :c => button()));

julia> f(t);
```
"""
macro layout(x)
    esc(layout_helper(x))
end

function layout_helper(expr)
    d = gensym()
    syms = OrderedDict()
    res = parse_function_call!(syms, d, expr, replace_wdg)
    isempty(syms) && return Expr(:(->), d, res)
    func = Expr(:(->), Expr(:tuple, values(syms)...), res)
    observs = (Expr(:call, :(Widgets.observe), key) for key in keys(syms))
    Expr(:(->), d, Expr(:call, :map, func, observs...))
end

replace_wdg(d, x...) = Expr(:call, :(Widgets.component), d, x...)
replace_wdg(s) = s

"""
`@layout!(d, x)`

Set `d.layout` to match the result of `Widgets.@layout(x)`. See [`Widgets.@layout`](@ref) for more information.

## Examples

```jldoctest map
julia> using DataStructures, InteractBase, CSSUtil

julia> t = Widgets.Widget{:test}(OrderedDict(:b => slider(1:100), :c => button()));

julia> @layout! t hbox(:b, CSSUtil.hskip(1em), :c);
```
"""
macro layout!(d, x)
    func = layout_helper(x)
    esc(:($d.layout = $func))
end

function div end

function defaultlayout(ui::Widget)
    div(values(ui.children)..., ui.display)
end
