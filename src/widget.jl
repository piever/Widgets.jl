function widget end

abstract type AbstractWidget{T, S} <: AbstractObservable{S}; end

mutable struct Widget{T, S} <: AbstractWidget{T, S}
    components::OrderedDict{Symbol, Any}
    output::AbstractObservable{S}
    scope
    layout::Function
    function Widget{T}(components::OrderedDict{Symbol, Any};
        output = Observable{Any}(nothing),
        scope = nothing,
        layout = defaultlayout(get_backend())) where {T, S}

        output_obs = to_abstractobservable(output)
        new{T, eltype(output_obs)}(components, to_abstractobservable(output), scope, layout)
    end
end

Widget{T}(components; kwargs...) where {T} = Widget{T}(OrderedDict{Symbol, Any}(Symbol(key) => val for (key, val) in components); kwargs...)

Widget{T}(; components = OrderedDict{Symbol, Any}(), kwargs...) where {T} = Widget{T}(components; kwargs...)

function Widget{T}(w::Widget; kwargs...) where {T}
    dict = Dict{Symbol, Any}(kwargs)
    for field in fieldnames(Widget)
        get!(dict, field, getfield(w, field))
    end
    Widget{T}(; dict...)
end

Widget(w::Widget{T}; kwargs...) where {T} = Widget{T}(w; kwargs...)
Widget(args...; kwargs...) = Widget{:default}(args...; kwargs...)

function widget(f::Function, args...; init = f(map(Observable._val, args)...), kwargs...)
    Widget{:output}(; output = map(f, args...; init = init), kwargs...)
end

widget(f::Function; kwargs...) = w -> widget(f, w; kwargs...)

widgettype(::AbstractWidget{T}) where {T} = T

"""
`scope(w::Widget)`

Return primary scope for widget `w` if it exists, `nothing` otherwise.
"""
scope(w::Widget) = w.scope

"""
`scope!(w::Widget, sc)`

sets up a primary scope `sc` for widget `w`
"""
function scope!(w::Widget, sc)
    w.scope = sc
    w
end

component(x, u) = getindex(x, u)
component(x, args...) = foldl(component, args, init = x)

components(w::Widget) = w.components

observe(u::Widget, args...) = observe(component(u, args...))
observe(u::Widget) = u.output

_getindex(ui::Widget, i::Symbol) = get(components(ui), i, nothing)

function Base.getindex(ui::Widget, i::Symbol)
    val = _getindex(ui, i)
    val === nothing || return val

    for (key, el) in components(ui)
        if el isa Widget
            val = getindex(el, i)
            val === nothing || return val
        end
    end
    return nothing
end

Base.getindex(ui::Widget, i::AbstractString) = getindex(ui, Symbol(i))
Base.setindex!(ui::Widget, val, i::Symbol) = setindex!(components(ui), val, i)
Base.setindex!(ui::Widget, val, i::AbstractString) = setindex!(ui, val, Symbol(i))

"""
`@auto(expr)`

Macro to automatize widget creation. Transforms `x = rhs` into `x = widget(rhs, label = "x")`.
"""
macro auto(args...)
    esc(auto_helper!(args...))
end

function auto_helper!(exprs...)
    res = Any[]
    dict = gensym()
    push!(res, :($dict = Widgets.OrderedDict{Symbol, Any}()))
    for expr in exprs
        @assert expr.head == :(=)
        var = expr.args[1]
        label = name2string(var)
        expr.args[2] = Expr(:call, :(Widgets.widget), expr.args[2], Expr(:kw, :label, label))
        push!(res, expr)
        push!(res, :($dict[$(Expr(:quote, var))] = $var))
    end
    push!(res, dict) 
    Expr(:block, res...)
end

# Placeholder for the input function, to define input widgets.
function input end

render(w::Widget) = w.layout(w)

Base.show(io::IO, x::Widget) = show(io, render(x))
Base.show(io::IO, m::MIME"text/html", x::Widget) = show(io, m, render(x))
Base.display(w::Widget) = display(render(w))
