__precompile__()

module Widgets

using Observables, DataStructures

import Observables: off, on, Observable, AbstractObservable, observe, ObservablePair

export Widget, widget, @layout!, node, scope, scope!

include("widget.jl")
include("utils.jl")
include("layout.jl")

end # module
