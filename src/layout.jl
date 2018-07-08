macro layout(x)
    esc(layout_helper(x))
end

function layout_helper(x)
    func, _ = extract_anonymous_function(x, replace_wdg)
    func
end

replace_wdg(d, x...) = Expr(:call, :(Widgets.component), d, x...)
replace_wdg(s) = s

macro layout!(d, x)
    func = layout_helper(x)
    esc(:(d.layout = $func))
end

function div end

function defaultlayout(ui::Widget)
    d, o = ui.display, ui.output
    output = d !== nothing ? (d,) : o !== nothing ? (o,) : ()
    div(values(ui.children)..., output...)
end
