function widget end

abstract type AbstractWidget{T, S} <: AbstractObservable{S}; end

mutable struct Widget{T, S} <: AbstractWidget{T, S}
    components::OrderedDict{Symbol, Any}
    output::AbstractObservable{S}
    scope
    layout::Function
    function Widget{T}(components = OrderedDict{Symbol, Any}();
        output::AbstractObservable{S} = Observable{Any}(nothing),
        scope = nothing,
        update = t -> (),
        layout = defaultlayout) where {T, S}

        child_dict = OrderedDict{Symbol, Any}(Symbol(key) => val for (key, val) in components)
        new{T, S}(child_dict, output, scope, layout)
    end
end

function Widget{T}(w::Widget; kwargs...) where {T}
    n = Widget{T}(components(w))
    dict = Dict(kwargs)
    for field in fieldnames(Widget)
        val = get(dict, field, getfield(w, field))
        setfield!(n, field, val)
    end
    n
end

Widget(w::Widget{T}; kwargs...) where {T} = Widget{T}(w; kwargs...)

widget() = Observable{Any}(Widget{:empty}())

function widget(f::Function, w; init = Observable{Any}(f(observe(w)[])), kwargs...)
    (init isa Observable) || (init = Observable{Any}(init))
    Widget{:output}(; output = map!(f, init, observe(w)), kwargs...)
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

Macro to automatize widget creation within an `@widget` call. Transforms `:x = rhs` into `:x = widget(rhs, label = "x")`.
"""
macro auto(expr)
    esc(auto_helper!(expr))
end

function auto_helper!(expr; wrap = false)
    @assert expr.head == :(=)
    label = name2string(expr.args[1])
    wrap && (label = Expr(:call, :^, label))
    expr.args[2] = Expr(:call, :(Widgets.widget), expr.args[2], Expr(:kw, :label, label))
    expr
end

# Placeholder for the input function, to define input widgets.
function input end
