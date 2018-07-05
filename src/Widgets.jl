__precompile__()

module Widgets

using Observables, DataStructures, Compat

export widget, @widget

include("widget.jl")
include("utils.jl")
include("layout.jl")
include("map.jl")

end # module
