# Widgets

[![Build Status](https://travis-ci.org/piever/Widgets.jl.svg?branch=master)](https://travis-ci.org/piever/Widgets.jl)
[![codecov.io](http://codecov.io/github/piever/Widgets.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/Widgets.jl?branch=master)

This package allows to create custom widgets using the JuliaGizmos packages and should be used in combination with InteractBase.

To create a custom widget use statement of the type `:a = ...` to add a child. You can refer to the child value elsewhere in the recipe using `:a`. `:a` will represent an `Observable`, you can either access it's value with `:a[]` or
```julia
using Widgets
using InteractBase, Observables, CSSUtil

@widget wdg function myui(s::Int)
    :a = slider(1:s) # :a will be a slider from 1 to the input of s
    :b = slider(1:$(:a)) # :b will be a slider from 1 to the value chosen in :a
    :c = toggle(false)
    :d = $(:c) ? :a[]+:b[] : :a[] - :b[] # The $ means: output updates as soon as :c changes, whereas the changing :a or :b won't update the widget
    @output!  wdg $(:c) ? $(:a) + $(:b) : $(:a) - $(:b)
    @display! wdg "The " * ($(:c) ? "sum" : "difference") * " is " * string($(_.output))
    @layout!  wdg vbox(hbox(:a, :b, :d), :c, _.display)
end
```

The new widget can then be created with:

```julia
myui(150)
```
