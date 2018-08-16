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
    parse_layout_call(d, expr, replace_wdg)
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
macro layout!(args...)
    esc(layout!_helper(args...))
end

function layout!_helper(d, x)
    func = layout_helper(x)
    quote
        $d.layout = $func
        $d
    end
end

function layout!_helper(x)
    d = gensym()
    res = layout!_helper(d, x)
    :($d -> $res)
end

div(args...; kwargs...) = node(:div, args...; kwargs...)

node(::AbstractWidget) = nothing

"""
`node(w::Widget)`

Return primary node for widget `w`
"""
node(w::Widget) = w.scope !== nothing ? w.scope.dom : nothing

function defaultlayout(ui::Widget)
    div(values(components(ui))..., observe(ui))
end

"""
`layout(f, w::Widget)`

Create a new `Widget` that is a copy of `w` and whose layout is the layout of `w` composed
with the function `f`.

## Examples

```julia
using InteractBase, CSSUtil, Widgets
w = button("OK")
Widgets.layout(w) do t
    hbox("Click here", t)
end
```
"""
function layout(f, w::Widget)
    g = layout(w)
    Widget(w, layout = x -> f(g(x)))
end

"""
`layout(w::Widget)`

Return the function that will be used to determine the layout of widget `w`.
"""
function layout(w::Widget)
    w.layout
end

layout!(f, w::Widget) = (w.layout = f; w)

(w::Widget)(args...; kwargs...) = layout(t->t(args...; kwargs...), w)
