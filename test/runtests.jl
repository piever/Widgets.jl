using Widgets, Observables
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

@testset "utils" begin
    d = Widgets.Widget{:test}(Dict(:a => 1, :b => Observable(2)))
    m = Widgets.@map d :a + :b[]
    n = Widgets.@map d :a + $(:b)
    @test m == 3
    @test n[] == 3
    d[:b][] = 3
    sleep(0.1)
    @test m == 3
    @test n[] == 4

    l = Widgets.@layout :a + :b[]
    @test l(d) == 4
end

@widget function myui(x)
    :a = x + 1
    :b = Observable(10)
    _.output = $(:b) + :a
    _.display = "The sum is "*string($(_.output))
    _.layout = _.display
end

@testset "widget" begin
    ui = myui(5)
    @test ui[:a] == 6
    @test ui[:b][] == 10
    @test ui.output[] == 16
    @test ui.display[] == ui.layout(ui)[] == "The sum is 16"

    ui = Widgets.widget(Val(:myui), 5)
    @test ui[:a] == 6
    @test ui[:b][] == 10
    @test ui.output[] == 16
    @test ui.display[] == ui.layout(ui)[] == "The sum is 16"

    ui[:b][] = 11
    sleep(0.1)
    @test ui.output[] == 17
    @test ui.display[] == ui.layout(ui)[] == "The sum is 17"
end
