"""
`@layout(d, x)`

Apply the expression `x` to the widget `d`, replacing e.g. symbol `:s` with the corresponding subwidget `d[:s]`
To create a layout that updates automatically as some `Widget` or `Observable` updates, use `\$(:s)`.
In this context, `_` refers to the whole widget. To use actual symbols, escape them with `^`, as in `^(:a)`.

## Examples

```jldoctest layout
julia> using DataStructures, InteractBase, CSSUtil

julia> t = Widgets.Widget{:test}(OrderedDict(:vertical => Observable(true), :b => slider(1:100), :c => button()));

julia> Widgets.@layout t $(:vertical) ? vbox(:b, CSSUtil.vskip(1em), :c) : hbox(:b, CSSUtil.hskip(1em), :c);
```

`@layout(x)`

Curried version of `@layout(d, x)`: anonymous function mapping `d` to `@layout(d, x)`.
"""
macro layout(args...)
    esc(layout_helper(args...))
end

function layout_helper(d, expr)
    syms = OrderedDict()
    res = parse_function_call!(syms, d, expr, replace_wdg)
    isempty(syms) && return res
    func = Expr(:(->), Expr(:tuple, values(syms)...), res)
    observs = (Expr(:call, :(Widgets.observe), key) for key in keys(syms))
    Expr(:call, :map, func, observs...)
end

function layout_helper(expr)
    d = gensym()
    Expr(:(->), d, layout_helper(d, expr))
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
