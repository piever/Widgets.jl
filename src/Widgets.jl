module Widgets

using Observables, OrderedCollections

import Observables: off, on, Observable, AbstractObservable, observe, ObservablePair, @map, @map!, @on

export Widget, widget, @layout!, node, scope, scope!

include("widget.jl")
include("utils.jl")
include("layout.jl")
include("widget_placeholder.jl")
include("backend.jl")
include("defaults.jl")
include("manipulate.jl")

end # module
