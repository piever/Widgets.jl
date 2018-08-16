using Widgets, Observables, DataStructures#, InteractBase, WebIO
using Widgets: Widget, @layout, @map, @map!, @on, widgettype
import Widgets: observe
using Test

@testset "utils" begin
    d = Widget{:test}(Dict(:a => 1, :b => Observable(2), :c => Widget{:test}(; output = Observable(5))))
    m = @map d :a + :b[] + :c[]
    n = @map d :a + $(:b) + :c[]
    @test m == 8
    @test n[] == 8
    d[:b][] = 3
    sleep(0.1)
    @test m == 8
    @test n[] == 9
    @test isa(d |> @map(:c), Observable)

    t = Widget{:test}(Dict(:a => Observable(2), :b => Observable(50)));
    Widgets.@map! t :a $(:b)
    observe(t, :b)[] = 15
    sleep(0.1)
    @test t[:a][] == 15

    v = [1]
    t = Widget{:test}(Dict(:a => Observable(2), :b => Observable(50)));
    Widgets.@on t v[1] += $(:b)
    observe(t, :b)[] = 15
    sleep(0.1)
    @test v[1] == 16
    observe(t, :b)[] = 30
    sleep(0.1)
    @test v[1] == 46

    d = Widget{:test}(Dict(:a => 1, :b => Observable(2), :c => Widget{:test}(; output = Observable(5))))
    m = d |> @layout :a + :b[]
    n = d |> @layout Observables.@map :a + &(:b)
    @test m == 3
    @test n[] == 3
    d[:b][] = 3
    sleep(0.1)
    @test m == 3
    @test n[] == 4
    @test isa(@layout(d, :c), Widget)
end

@widget wdg function myui(x)
    :a = x + 1
    :b = Observable(10)
    # @auto :x = "aa"
    @output!  wdg $(:b) + :a
    @display! wdg "The sum is "*string($(_.output))
    @layout!  wdg _.display
end

@testset "widget" begin
    ui = myui(5)
    @test ui[:a] == 6
    @test ui[:b][] == 10
    @test ui.output[] == 16
    @test ui.display[] == ui.layout(ui)[] == "The sum is 16"
    # @test widgettype(ui[:x]) == :textbox
    # @test observe(ui[:x])[] == "aa"


    ui = Widgets.widget(Val(:myui), 5)
    @test ui[:a] == 6
    @test ui[:b][] == 10
    @test ui.output[] == 16
    @test ui.display[] == ui.layout(ui)[] == "The sum is 16"

    ui = Widgets.@nodeps myui(5)
    @test ui[:a] == 6
    @test ui[:b][] == 10
    @test ui.output[] == 16
    @test ui.display[] == ui.layout(ui)[] == "The sum is 16"

    ui[:b][] = 11
    sleep(0.1)
    @test ui.output[] == 17
    @test ui.display[] == ui.layout(ui)[] == "The sum is 17"
end

# @testset "auto" begin
#     Widgets.@auto x = 10
#     @test observe(x)[] == 10
#     @test widgettype(x) == :spinbox
# end

@testset "pair" begin
    v = Widgets.ObservablePair(Observable(1.0), f = exp, g = log)
    @test v.second[] ≈ ℯ
    v.first[] = 0
    @test v.second[] ≈ 1
    v.second[] = 2
    @test v.first[] ≈ log(2)

    obs = Observable(Observable(2))
    o2 = Widgets.unwrap(obs)

    o2[] = 12
    sleep(0.1)
    @test obs[][] == 12
    obs[][] = 22
    sleep(0.1)
    @test o2[] == 22
    obs[] = Observable(11)
    sleep(0.1)
    @test o2[] == 11
end

# @testset "layout" begin
#     wdg = slider(1:100)
#     wdg2 = wdg(style = Dict("color" => "red"))
#     n = WebIO.render(wdg2)
#     @test props(n)[:style]["color"] == "red"
#     @test Widgets.node(wdg) isa Node
# end
