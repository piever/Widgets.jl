function compose_helper(expr)
    syms = OrderedDict()
    d = gensym()
    v = gensym()
    res = parse_delayed!(syms, d, expr, takevalue = false)
    args = Any[:($d = Widgets.Widget{:composeinput}())]
    for (sym, name) in syms
        push!(args, Expr(:call, :setindex!, d, sym, quotenode(name)))
    end
    dspl = quote
        $v = $res
        $d.output = $v.output
        $d.display = $v
        $d
    end
    push!(args, dspl)
    Expr(:block, args...)
end

macro compose(expr)
    esc(compose_helper(expr))
end
