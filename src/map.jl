function map_helper(d, expr::Expr)
    syms = OrderedDict()
    res = parse_function_call!(syms, d, expr, replace_obs)
    isempty(syms) && return res
    func = Expr(:(->), Expr(:tuple, values(syms)...), res)
    Expr(:call, :map, func, keys(syms)...)
end

macro map(d, expr)
    esc(map_helper(d, expr))
end

replace_obs(s) = s

replace_obs(d, x...) = Expr(:call, :(Widgets.observe), replace_wdg(d, x...))
