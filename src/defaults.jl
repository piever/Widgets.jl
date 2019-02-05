for op in [:filepicker, :datepicker, :colorpicker, :timepicker, :spinbox,
           :autocomplete, :input, :dropdown, :checkbox, :toggle, :togglecontent,
           :textbox, :textarea, :button, :slider, :rangeslider, :rangepicker, :entry,
           :radiobuttons, :checkboxes, :toggles, :togglebuttons, :tabs, :tabulator, :accordion,
           :wdglabel, :latex, :alert, :highlight, :notifications, :mask, :tooltip!, :confirm]
    @eval begin
        function $op(args...; kwargs...)
            length(args) > 0 && args[1] isa AbstractBackend &&
                error("Function " * string($op) * " was about to overflow: check the signature")
            $op(get_backend(), args...; kwargs...)
        end

        widget(::Val{$(Expr(:quote, op))}, args...; kwargs...) = $op(args...; kwargs...)
    end
end

widget(x::Observable; label = nothing) = widget(get_backend(), x; label = label)
