__precompile__()

module Widgets

using Observables, DataStructures

import Observables: off, on, Observable, AbstractObservable, observe

export Widget, widget, @widget, @layout!, node, scope, scope!

include("widget.jl")
include("utils.jl")
include("layout.jl")
include("observablepair.jl")

end # module
