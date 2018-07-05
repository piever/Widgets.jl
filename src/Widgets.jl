__precompile__()

module Widgets

using Observables, DataStructures

export widget, ui, @ui

include("ui.jl")
include("utils.jl")
include("layout.jl")
include("map.jl")

end # module
