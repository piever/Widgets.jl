__precompile__()

module Widgets

using Observables, DataStructures, Compat

import Observables: off

export widget, @widget, @layout!, @output!, @display!

include("widget.jl")
include("utils.jl")
include("layout.jl")
include("map.jl")
include("observablepair.jl")
include("output.jl")

end # module
