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

macro on(args...)
    esc(on_helper(args...))
end
