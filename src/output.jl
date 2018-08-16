"""
`@output!(d, x)`

Computes `Widgets.@map(d, x)` and sets `d.output` to be the result (see [`Widgets.@map`](@ref) for more details).
`d.display` is also set by default to match `d.output`. To have a custom display use `@display!(d, expr)` _after_
`@output!(d, x)`
"""
macro output!(d, x)
    Base.depwarn("Widgets.@output! is deprecated", "output!")
    func = map_helper(d, x)
    quote
        $d.output = $func
        $d.display = map(identity, $d.output)
    end |> esc
end

"""
`@display!(d, x)`

Computes `Widgets.@map(d, x)` and sets `d.display` to be the result (see [`Widgets.@map`](@ref) for more details).
"""
macro display!(d, x)
    Base.depwarn("Widgets.@display! is deprecated", "display!")
    func = map_helper(d, x)
    esc(:($d.display = $func))
end
