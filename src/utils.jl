isquotenode(x) = false
isquotenode(x::QuoteNode) = true

quotenode(x) = QuoteNode(x)

iswidgettuple(x) = false
iswidgettuple(x::Expr) = x.head == :tuple && all(isquotenode, x.args) && length(x.args) > 0

parse_layout_call(d, x, func, args...) = parse_layout_call!(OrderedDict(), d, x, func, args...)

function parse_layout_call!(syms, d, x::Expr, func, args...)
    if x.head == :. && length(x.args) == 2 && isquotenode(x.args[2])
        Expr(x.head, parse_layout_call!(syms, d, x.args[1], func, args...), x.args[2])
    elseif x.head == :call && length(x.args) == 2 && x.args[1] == :^
        x.args[2]
    elseif iswidgettuple(x)
        return parse_layout_call!(syms, d, x.args[1], func, x.args[2:end]..., args...)
    else
        Expr(x.head, (parse_layout_call!(syms, d, arg, func, args...) for arg in x.args)...)
    end
end

function parse_layout_call!(syms, d, x, func, args...)
    if isquotenode(x)
        func(d, x, args...)
    elseif x == :(_)
        func(d, args...)
    else
        x
    end
end

extract_name(s) = s
extract_name(s::QuoteNode) = s.value
function extract_name(expr::Expr)
    isquotenode(expr) && return extract_name(expr.args[1])
    expr.head == :macrocall && return extract_name(expr.args[1])
    expr.head == :. || return nothing
    extract_name(expr.args[2])
end

"""
`@nodeps(expr)`

Macro to remove need to depend on package X that defines a recipe to use it in one's own recipe.
For example, InteractBase defines `dropwdown` recipe. To use `dropdown` in a recipe in a package,
without depending on InteractBase, wrap the `dropdown` call in the `@nodeps` macro:

```julia
function myrecipe(i)
    label = "My recipe"
    wdg = Widgets.@nodeps dropdown(i)
    Widget(["label" => label, "dropdown" => wdg])
end
```
"""
macro nodeps(expr)
    @assert expr isa Expr
    @assert expr.head == :call
    shortname = extract_name(expr.args[1])
    qn = quotenode(shortname)
    esc(Expr(:call, :(Widgets.widget), Expr(:call, :Val, qn), expr.args[2:end]...))
end

name2string(x::Symbol) = Expr(:call, :string, Expr(:quote, x))
name2string(x::QuoteNode) = Expr(:call, :string, x)
name2string(x::Expr) = name2string(x.args[end])

isijulia() = isdefined(Main, :IJulia) && Main.IJulia.inited
