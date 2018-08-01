"""
`@apply(args...)`
Concatenate a series of operations. Non-macro operations from Widgets, are supported via
 the `_` curryfication syntax.
"""
macro apply(args...)
    esc(Expr(:call, thread(args[end]), args[1:end-1]...))
end

function thread(ex)
     if isexpr(ex, :block)
          thread(rmlines(ex).args...)
     elseif isa(ex, Expr)
          us = find(ex.args .== :(_))
          i = gensym()
          ex.args[us] .= i
          isempty(us) ? ex : Expr(:(->), i, ex)
     else
          ex
     end
end

thread(exs...) = mapreduce(thread, (ex1, ex2) -> Expr(:call, Symbol(∘), ex2, ex1), exs)
