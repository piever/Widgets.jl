ui(w; kwargs...) = Widget{:ui}(kwargs; output = observe(w), display = w)
ui(f::Function; kwargs...) = ui(map(f, (observe(val) for (key,  val) in kwargs)...); kwargs...)
ui(f::Function, w::Observable; kwargs...) = ui(map!(f, w, (observe(val) for (key,  val) in kwargs)...); kwargs...)
ui() = Observable{Any}(nothing)

macro ui(x)
    d = gensym()
    w = map_helper(d, x)
    :($d -> Widgets.ui($w; input = $d))
end
