__precompile__()

module Widgets

using Observables, DataStructures, Compat

import Observables: off, on, Observable

export widget, @widget, @layout!, @output!, @display!, @on, @map!, node, scope, scope!

include("widget.jl")
include("utils.jl")
include("layout.jl")
include("map.jl")
include("on.jl")
include("observablepair.jl")
include("output.jl")
include("delayed.jl")

end # module
