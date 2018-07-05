function widget end

abstract type AbstractWidget; end

mutable struct Widget{T} <: AbstractWidget
    children::OrderedDict{Symbol, Any}
    output
    display
    scope
    update::Function
    layout::Function
    function Widget{T}(children = OrderedDict{Symbol, Any}();
        output = nothing,
        display = nothing,
        scope = nothing,
        update = t -> (),
        layout = defaultlayout) where {T}

        child_dict = OrderedDict{Symbol, Any}(Symbol(key) => val for (key, val) in children)
        new{T}(child_dict, output, display, scope, update, layout)
    end
end

function Widget{T}(w::Widget; kwargs...) where {T}
    n = Widget{T}(w.children)
    dict = Dict(kwargs)
    for field in fieldnames(Widget)
        val = get(dict, field, getfield(w, field))
        setfield!(n, field, val)
    end
    n
end

widgettype(::Widget{T}) where {T} = T

observe(x) = x
observe(u::Widget) = u.output
observe(u::Widget, s) = getindex(u, s)

function descendants(ui::Widget)
    desc = copy(ui.children)
    for (key, el) in ui.children
        if el isa Widget
            merge!(desc, descendants(el))
        end
    end
    desc
end

Base.getindex(ui::Widget, i::Symbol) = get(ui.children, i, descendants(ui)[i])
Base.getindex(ui::Widget, i::AbstractString) = getindex(ui, Symbol(i))
Base.setindex!(ui::Widget, val, i::Symbol) = setindex!(ui.children, val, i)
Base.setindex!(ui::Widget, val, i::AbstractString) = setindex!(ui, val, Symbol(i))

replace_ref(s) = s

replace_ref(d, x...) = foldl((a,b) -> Expr(:ref, a, b), d, x)

macro widget(func_call)
    func_call.head == :function || error("@ui accepts only function definitions")
    func_signature, func_body = func_call.args
    func_name = func_signature.args[1]
    @assert func_body.head == :block
    d = gensym()
    v = func_body.args
    for (i, line) in enumerate(v)
        if iswidgetassignment(line)
            line.args[1] = parse_function_call(d, line.args[1], replace_ref)
            line.args[2] = map_helper(d, line.args[2])
        elseif islayoutassignment(line)
            line.args[1] = parse_function_call(d, line.args[1], replace_ref)
            line.args[2] = layout_helper(line.args[2])
        else
            v[i] = parse_function_call(d, line, replace_obs)
        end
    end
    pushfirst!(v, :($d = Widgets.Widget{$(quotenode(extract_name(func_name)))}()))
    push!(v, d)
    (extract_name(func_name) == :widget) && return esc(func_call)
    quote
        $func_call
        Widgets.widget(::Val{$(quotenode(func_name))}, args...; kwargs...) = $func_name(args...; kwargs...)
        export $func_name
    end |> esc
end
