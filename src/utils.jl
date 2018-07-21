isquotenode(::Any) = false
isquotenode(x::Expr) = x.head == :quote
isquotenode(x::QuoteNode) = true

@static if VERSION < v"0.7.0-DEV.2005"
    quotenode(x) = Expr(:quote, x)
else
    quotenode(x) = QuoteNode(x)
end

iswidget(x) = isquotenode(x) || x in [Expr(:., :_, quotenode(:output)), Expr(:., :_, quotenode(:display))]
iswidgettuple(x) = false
iswidgettuple(x::Expr) = x.head == :tuple && all(isquotenode, x.args)

iswidgetassignment(x) = false

function iswidgetassignment(expr::Expr)
    expr.head == :(=) || return false
    iswidget(expr.args[1])
end

parse_function_call(d, x, func, args...) = parse_function_call!(OrderedDict(), d, x, func, args...)

function parse_function_call!(syms, d, x::Expr, func, args...)
    if x.head == :$ && (all(iswidget, x.args) || length(x.args) == 1 && iswidgettuple(x.args[1]))
        sym = parse_function_call(d, x.args[1], func, x.args[2:end]..., args...)
        new_var = get(syms, sym, gensym())
        syms[sym] = new_var
        new_var
    elseif x.head == :. && length(x.args) == 2 && isquotenode(x.args[2])
        Expr(x.head, parse_function_call!(syms, d, x.args[1], func, args...), x.args[2])
    elseif isquotenode(x)
        func(d, x, args...)
    elseif x.head == :call && length(x.args) == 2 && x.args[1] == :^
        x.args[2]
    elseif x.head == :& && length(x.args) == 1
        return parse_function_call!(syms, d, x.args[1], func, args...)
    elseif iswidgettuple(x)
        return parse_function_call!(syms, d, x.args[1], func, x.args[2:end]..., args...)
    else
        Expr(x.head, (parse_function_call!(syms, d, arg, func, args...) for arg in x.args)...)
    end
end

function parse_function_call!(syms, d, x, func, args...)
    if isquotenode(x)
        func(d, x, args...)
    elseif x == :(_)
        func(d, args...)
    else
        x
    end
end

function extract_anonymous_function(x, func, args...)
    syms = OrderedDict()
    data = gensym()
    function_call = parse_function_call!(syms, data, x, func, args...)
    anon_func = Expr(:(->), data, function_call)
    return anon_func, syms
end

extract_name(s) = s
function extract_name(expr::Expr)
    isquotenode(expr) && return expr.args[1]
    @assert expr.head == :.
    extract_name(expr.args[2])
end

"""
`@nodeps(expr)`

Macro to remove need to depend on package X that defines a recipe to use it in one's own recipe.
For example, InteractBase defines `dropwdown` recipe. To use `dropdown` in a recipe in a package,
without depending on InteractBase, wrap the `dropdown` call in the `@nodeps` macro:

```julia
@widget wdg function myrecipe(i)
    :label = "My recipe"
    :dropdown = Widgets.@nodeps dropdown(i)
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
