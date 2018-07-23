function parse_delayed!(syms, d, x::Expr; counter = Ref(0))
    if x.head == :$
        sym = x.args[1]
        new_var = get(syms, sym, gensym())
        counter[] += 1
        syms[sym] = Symbol("input$(counter[])")
        Expr(:call, :getindex, Expr(:call, :(Widgets.observe), Expr(:call, :getindex, d, quotenode(syms[sym]))))
    elseif x.head == :call && length(x.args) == 2 && x.args[1] == :^
        x.args[2]
    else
        Expr(x.head, (parse_delayed!(syms, d, arg; counter = counter) for arg in x.args)...)
    end
end

parse_delayed!(syms, d, x; kwargs...) = x

macro delayed(expr)
    esc(delayed_helper(expr))
end

function delayed_helper(expr)
    syms = OrderedDict()
    d = gensym()
    v = gensym()
    res = parse_delayed!(syms, d, expr)
    args = Any[:($d = Widgets.Widget{:delayedinput}())]
    for (sym, name) in syms
        push!(args, Expr(:call, :setindex!, d, sym, quotenode(name)))
    end
    dspl = quote
        $d.display = Widgets.Observable{Any}(Widgets.div())
        $d[:submit] = Widgets.widget(Val(:button), "Submit")
        Widgets.on(Widgets.observe($d[:submit])) do x
            $v = $res
            $d.output = $v.output
            $d.display[] = $v
        end
        $d
    end
    push!(args, dspl)
    Expr(:block, args...)
end
