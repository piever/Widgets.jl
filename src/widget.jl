function widget end

abstract type AbstractWidget; end

mutable struct Widget{T} <: AbstractWidget
    children::OrderedDict{Symbol, Any}
    output::Observable
    display::Observable
    scope
    update::Function
    layout::Function
    function Widget{T}(children = OrderedDict{Symbol, Any}();
        output = Observable{Any}(nothing),
        display = Observable{Any}(nothing),
        scope = nothing,
        update = t -> (),
        layout = defaultlayout) where {T}

        child_dict = OrderedDict{Symbol, Any}(Symbol(key) => val for (key, val) in children)
        new{T}(child_dict, output, display, scope, update, layout)
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

widgettype(::Widget{T}) where {T} = T

component(x, u) = getindex(x, u)
component(x::Observable, u) = unwrap(map(t -> component(t, u), x))
component(x, args...) = foldl(component, x, args)

components(w::Widget) = w.children

observe(x) = x
observe(u::Widget) = u.output
observe(o::Observable) = o[] isa Widget ? unwrap(map(observe, o)) : o
observe(args...) = observe(component(args...))

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

replace_ref(s) = s

replace_ref(d, x...) = foldl((a,b) -> Expr(:ref, a, b), d, x)

"""
`@widget(wdgname, func_call)`

Special macro to create "recipes" for custom widgets. The `@widget` macro takes to argument, a variable
name `wdgname` and a function call `func_call`. The function call is changed by the macro in several ways:
- an extra line is added at the beginning to initiliaze a variable called `wdgname::Widget` that can be used to refer to the widget in the function body
- all lines of the type `sym::Symbol = expr` are replaced with `wdgname[sym] = @map(wdgname, expr)`, see [`Widgets.@map`](@ref) for more details
- an extra line is added at the end to return `wdgname`

The macro then registers the function `func_call` and exports it.
It also overloads the `widget` function with the following signature:

`Widgets.widget(::Val{Symbol(func_name)}, args...; kwargs..) = func_name(args...; kwargs...)`
"""
macro widget(args...)
    @assert 1 <= length(args) <= 2
    func_call = args[end]
    d = length(args) == 2 ? args[1] : gensym(:widget)
    func_call.head == :function || error("@widget accepts only function definitions")
    func_signature, func_body = func_call.args
    func_name = func_signature.args[1]
    @assert func_body.head == :block
    v = func_body.args
    for (i, line) in enumerate(v)
        if extract_name(line) == Symbol("@auto")
            expr = auto_helper!(line.args[2], wrap = true)
            line.head = expr.head
            line.args = expr.args
        end
        if iswidgetassignment(line)
            line.args[2] = map_helper(d, line.args[2])
            line.args[1] = parse_function_call(d, line.args[1], replace_ref)
        end
    end
    shortname = extract_name(func_name)
    qn = quotenode(shortname)
    pushfirst!(v, :($d = Widgets.Widget{$qn}()))
    push!(v, d)
    (shortname == :widget) && return esc(func_call)
    quote
        Base.@__doc__ $func_call
        Widgets.widget(::Val{$qn}, args...; kwargs...) = $func_name(args...; kwargs...)
        export $func_name
    end |> esc
end

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
