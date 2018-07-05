macro layout(x)
    esc(layout_helper(x))
end

function layout_helper(x)
    func, _ = extract_anonymous_function(x, replace_wdg)
    func
end

replace_wdg(d, x...) = foldl((a,b) -> Expr(:call, :(UIRecipesBase.observe), a, b), d, x)
replace_wdg(s) = s

macro layout!(d, x)
    func = layout_helper(x)
    esc(:(d.layout = $func))
end

function div end
