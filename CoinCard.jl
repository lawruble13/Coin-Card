__precompile__(false);
module CoinCard
needed = ["JuMP", "Cbc", "Ipopt", "Compose"]
using Pkg
for m in needed
    if !haskey(Pkg.installed(), m)
        Pkg.add(m)
    end
end

using JuMP, Cbc, Ipopt, Compose
import Base.show

export CoinProblem,
    CoinProblem!,
    CoinStack,
    Coin,
    getCoinSet,
    getCoinStacks,
    getCoinLayout,
    generateSCAD,
    generateSVG,
    CanadianCoins


"This type describes a coin. It is not any single coin, but describes a class of coins (e.g. it may describe nickels, but not any specific nickel.)"
mutable struct Coin
    nm::AbstractString # The name of the coin
    r::Float64         # Radius of the smallest circle CICRUMSCRIBING the coin
    h::Float64         # Height of the coin
    v::UInt64          # Value of the coin (units)
    max_stack::UInt64  # The maximum number of this coin that can be put in a stack
    used::UInt64       # The number of this coin used in the coin set for a problem
end

Base.show(io::IO, C::Coin) =
    print(io, C.nm, " (", Int(C.v), " units, ", 2 * C.r, " ⌀, ", C.h, ")")

"This type describes a stack of coins. The height of the stack (n) should be <= C.max_stack. This describes a specific stack of coins."
mutable struct CoinStack
    C::Coin            # The coin being stacked
    n::UInt64          # The number of coins in the stack
    x::Float64         # The x position of the stack of coins
    y::Float64         # The y position of the stack of coins
end
Base.show(io::IO, CS::CoinStack) =
    print(io, "A stack of ", CS.n, " ", CS.C, ", located at (", CS.x, ", ", CS.y, ")")

"""
This type describes a problem configuration. The parameters defining the
    problem are C (the description of possible coins to use), desired_values
    (the values that should be makable using the coins), W (the width of the
    rectangle that the coin stacks should fit in), and H (the height of the
    rectangle that the coin stacks should fit in). The other values should not
    be set by the user.
"""
mutable struct CoinProblem
    C::Array{Coin,1}                  # The set of coins that may be used to solve the problem
    desired_values::Array{UInt64,1}   # The set of values that should be obtainable using the coins
    W::Float64                         # The desired maximum width of the solution
    H::Float64                         # The desired maximum height of the solution

    setValid::Bool                     # Indicates that the coins in C are the coins that should be used
    failed_DV::Array{UInt64,1}        # The values that could not be obtained using the coins
    CS::Array{CoinStack,1}            # The set of coin stacks that should be laid out
    stacksValid::Bool                  # Indicates that the stacks in CS are the stacks that should be used
    margin::Float64                    # Records the maximum amount by which the layout exceeds the desired width and/or height
    layoutValid::Bool                  # Indicates that the layout recorded in CS is valid
end

function Base.show(io::IO, CP::CoinProblem)
    println(io, "Desired values: ", Array{Int,1}(CP.desired_values))
    println(io, "Card size: (", CP.W, ", ", CP.H, ")")
    println(io, "Coins: ")
    for c in CP.C
        println(io, "\t", c)
    end
    if CP.stacksValid
        println(io, "Stacks: ")
        for s in CP.CS
            println(io, "\t", s)
        end
    else
        println(io, "Stacks: Not generated")
    end
    if CP.layoutValid
        println(io, "Layout: generated, max margin of ", CP.margin)
    else
        println(io, "Layout: not generated")
    end
end

"""
This function returns a problem configuration. All of the user definable
    problem parameters are named parameters.
"""
function CoinProblem(;
    coins::Array{Coin,1} = Array{Coin,1}(undef, 0),
    W::Float64 = 0.0,
    H::Float64 = 0.0,
    desired_values::Array{Int64,1} = Array{Int64,1}(undef, 0),
)
    P = CoinProblem(
        coins,
        desired_values,
        W,
        H,
        false,
        Array{Int64,1}(undef, 0),
        Array{CoinStack,1}(undef, 0),
        false,
        0.0,
        false,
    )
    for i = 1:length(coins)
        if (coins[i].used > 0)
            P.setValid = true
        elseif (coins[i].used < 0)
            error("You cannot have a negative number of coins.")
        end
    end
    return P
end

"""
This function returns the problem configuration with the new coin array.
"""
function CoinProblem(P::CoinProblem, coin_arr::Array{Coin,1})
    NP = deepcopy(P)
    NP.coin_arr = coin_arr
    for i = 1:length(coins)
        if (coins[i].used > 0)
            NP.setValid = true
        elseif (coins[i].used < 0)
            error("You cannot have a negative number of coins.")
        end
    end
    NP.setValid = NP.stacksValid = NP.layoutValid = false
    return NP
end

"This function returns the problem configuration with the new coins."
function CoinProblem(P::CoinProblem, coin::Coin, coins::Coin...)
    return CoinProblem(P, vcat(coin, collect(coin)))
end

"This function sets the coin array of the problem configuration to the new coin array."
function CoinProblem!(P::CoinProblem, coin_arr::Array{Coin,1})
    o_sv = P.setValid
    P.setValid = false
    for i = 1:length(coins)
        if (coins[i].n > 0)
            P.setValid = true
        elseif (coins[i].n < 0)
            P.setValid = o_sv
            error("You cannot have a negative number of coins.")
        end
    end
    P.C = deepcopy(coin_arr)
    P.setValid = P.stacksValid = P.layoutValid = false
    return P
end

"This function sets the coin array of the problem configuration to the new coins."
function CoinProblem!(P::CoinProblem, coin::Coin, coins::Coin...)
    return CoinProblem!(P, vcat(coin, collect(coins)))
end

function CoinProblem(P::CoinProblem, desired_values::Array{Int64,1})
    NP = deepcopy(P)
    NP.desired_values = desired_values
    NP.setValid = NP.stacksValid = NP.layoutValid = false
    return NP
end

function CoinProblem(P::CoinProblem, dv::Int64, dvs::Int64...)
    return CoinProblem(P, vcat(dv, collect(dvs)))
end

function CoinProblem!(P::CoinProblem, desired_values::Array{Int64,1})
    P.desired_values = deepcopy(desired_values)
    P.setValid = P.stacksValid = P.layoutValid = false
    return P
end

function CoinProblem!(P::CoinProblem, dv::Int64, dvs::Int64...)
    return CoinProblem!(P, vcat(dv, collect(dvs)))
end

function CoinProblem(P::CoinProblem, W::Float64, H::Float64)
    NP = deepcopy(P)
    NP.W = W
    NP.H = H
    NP.layoutValid = false
    return NP
end

function CoinProblem!(P::CoinProblem, W::Float64, H::Float64)
    P.W = W
    P.H = H
    P.layoutValid = false
    return P
end

function getCoinSet(P::CoinProblem)
    N = length(P.C)
    Ndv = length(P.desired_values)
    m = Model(Cbc.Optimizer)
    set_optimizer_attribute(m, "logLevel", 0)
    CA = map((c) -> pi * (c.r)^2, P.C)
    CV = map((c) -> c.v, P.C)

    @variable(m, CF[1:Ndv], Bin)
    @variable(m, U[1:N] >= 0, Int)
    @variable(m, US[1:N] >= 0, Int)
    @variable(m, UTF[1:Ndv, 1:N] >= 0, Int)

    if (P.setValid)
        @constraint(m, U .>= ((c) -> c.used).(P.C))
        @constraint(m, U .<= ((c) -> c.used).(P.C))
    end

    @constraint(m, US .>= U ./ ((c) -> c.max_stack).(P.C))
    @constraint(m, UTF .<= ones(Ndv, 1) * transpose(U))
    @constraint(m, UTF * CV .>= P.desired_values .* CF)
    @constraint(m, UTF * CV .<= P.desired_values)

    @objective(
        m,
        Min,
        (Ndv - sum(CF[i] for i = 1:Ndv)) *
        (sum(maximum(P.desired_values) / CV[i] for i = 1:N) + 1) *
        maximum(CA) +
        sum(U[i] * CA[i] for i = 1:N) +
        sum(US[i] * CA[i] for i = 1:N)
    )

    optimize!(m)

    P.failed_DV = round.(filter(x -> x < 0.5, value.(CF) .* (P.desired_values .+ 1)) .- 1)
    ((c, u) -> c.used = u).(P.C, round.(value.(U)))
    P.setValid = true
    P.stacksValid = false
    P.layoutValid = false
    return ((c) -> c.used).(P.C)
end

function getCoinStacks(P::CoinProblem)
    P.CS = Array{CoinStack,1}(undef, 0)
    if (!P.setValid)
        error("Invalid coin set")
    end
    if (P.stacksValid)
        return P.CS
    end
    for c in P.C
        u = 0
        while c.used - u != 0
            if c.used - u > c.max_stack
                ncs = CoinStack(c, c.max_stack, 0.0, 0.0)
                P.CS = [P.CS; ncs]
                u += c.max_stack
            else
                ncs = CoinStack(c, c.used - u, 0.0, 0.0)
                P.CS = [P.CS; ncs]
                u = c.used
            end
        end
    end
    P.stacksValid = true
    P.layoutValid = false
    return P.CS
end

function getCoinLayout(
    P::CoinProblem;
    max_margin::Float64 = 0.0,
    max_stack::Int64 = 20,
    force::Bool = true,
)
    if (!P.setValid)
        if (force)
            getCoinSet(P)
        else
            error("Invalid coin set")
        end
    end
    if (!P.stacksValid)
        if (force)
            getCoinStacks(P)
        else
            error("Invalid coin stacks")
        end
    end
    if (P.layoutValid)
        return true
    end
    N = length(P.CS)
    m = Model(Ipopt.Optimizer)
    r = ((s) -> s.C.r).(P.CS)

    @variable(m, r[i] <= x_app[i = 1:N] <= P.W - r[i])
    @variable(m, r[i] <= y_app[i = 1:N] <= P.H - r[i])

    @variable(m, x_act[1:N])
    @variable(m, y_act[1:N])

    @variable(m, OR >= 0)
    @variable(m, OL >= 0)
    @variable(m, OT >= 0)
    @variable(m, OB >= 0)
    @variable(m, O >= 0)

    @variable(m, UX >= 0)
    @variable(m, UY >= 0)

    @constraint(m, [i = 1:N], OR >= x_act[i] - x_app[i])
    @constraint(m, [i = 1:N], OL >= x_app[i] - x_act[i])
    @constraint(m, [i = 1:N], OT >= y_act[i] - y_app[i])
    @constraint(m, [i = 1:N], OB >= y_app[i] - y_act[i])

    @constraint(m, [i = 1:N, j = 1:N], UX >= x_act[i] - x_act[j])
    @constraint(m, [i = 1:N, j = 1:N], UY >= y_act[i] - y_act[j])

    @constraint(
        m,
        [i = 1:N, j = i+1:N],
        (x_act[i] - x_act[j])^2 + (y_act[i] - y_act[j])^2 >= (r[i] + r[j])^2
    )

    @constraint(m, O >= OR)
    @constraint(m, O >= OL)
    @constraint(m, O >= OT)
    @constraint(m, O >= OB)

    @objective(m, Min, (O + 1)^2 + UX + UY)

    optimize!(m)
    if (value(O) > max_margin)
        increaseStacks(P)
        if (maximum(((s) -> s.n).(P.CS)) > max_stack)
            return false
        end
        getCoinSet(P)
        getCoinStacks(P)
        return getCoinLayout(
            P,
            max_margin = max_margin,
            max_stack = max_stack,
            force = false,
        )
    else
        ((s, x, y) -> (s.x = x; s.y = y)).(P.CS, value.(x_act), value.(y_act))
        P.layoutValid = true
        P.margin = value(O)
        return true
    end
end

function increaseStacks(P::CoinProblem)
    m = Model(Cbc.Optimizer)
    set_optimizer_attribute(m, "logLevel", 0)
    N = length(P.C)
    CH = ((c) -> c.h).(P.C)

    @variable(m, SN[1:N] >= 1, Int)
    @variable(m, MH >= 0)

    @constraint(m, [i = 1:N], MH >= SN[i] * P.C[i].h)
    @constraint(m, [i = 1:N], SN[i] >= P.C[i].max_stack)
    @constraint(m, sum(SN[i] for i = 1:N) >= sum(P.C[i].max_stack for i = 1:N) + 1)

    @objective(m, Min, 100 * N * MH - sum(SN[i] for i = 1:N))

    optimize!(m)

    P.setValid = false
    P.stacksValid = false
    P.layoutValid = false

    ((c, n) -> (c.max_stack = n)).(P.C, value.(SN))
    return
end

function generateSCAD(P::CoinProblem; BPH::Float64 = 0.3, folder::AbstractString = pwd())
    if (!P.layoutValid)
        error(
            "Layout not computed",
            "Call getCoinLayout(P) before a call to either generateSCAD() or generateSVG().",
        )
        return
    end
    touch(folder * "/coincard.scad")
    open(folder * "/coincard.scad", "w") do f
        write(
            f,
            """
       h = $((maximum(((s)->s.C.h*s.n).(P.CS))*1.1));
       hbp = $BPH;
       W = $(P.W);
       H = $(P.H);
       B = $(P.margin+0.1);
       CR = 2.5;
       difference(){
           translate(v=[-B, -B, 0]){
               cube([W+2*B, H+2*B, h+hbp]);
           };
       """,
        )
        for s in P.CS
            write(
                f,
                """
           translate(v=[$(s.x),$(s.y),0]){
               translate(v=[0,0,hbp+h-$(s.C.h*s.n)]) cylinder(h=h*1.1,r=$(s.C.r)+0.2);
               translate(v=[0,0,-0.05*hbp]) cylinder(h=1.1*hbp+h,r=($(s.C.r)+0.2)/2);
           };
       """,
            )
        end
        write(
            f,
            """
           difference(){
               translate(v=[-B-0.01,-B-0.01,-h*0.1]){
                   cube([CR, CR, h*1.2+hbp]);
               };
               translate(v=[-B+CR,-B+CR,-h*0.1]){
                   cylinder(h=h*1.2+hbp, r=CR);
               };
           };
           difference(){
               translate(v=[W+B-CR+0.01,-B-0.01,-h*0.1]){
                   cube([CR, CR, h*1.2+hbp]);
               };
               translate(v=[W+B-CR,-B+CR,-h*0.1]){
                   cylinder(h=h*1.2+hbp, r=CR);
               };
           };
           difference(){
               translate(v=[-B-0.01,H+B-CR+0.01,-h*0.1]){
                   cube([CR, CR, h*1.2+hbp]);
               };
               translate(v=[-B+CR,H+B-CR,-h*0.1]){
                   cylinder(h=h*1.2+hbp, r=CR);
               };
           };
           difference(){
               translate(v=[W+B-CR+0.01,H+B-CR+0.01,-h*0.1]){
                   cube([CR, CR, h*1.2+hbp]);
               };
               translate(v=[W+B-CR,H+B-CR,-h*0.1]){
                   cylinder(h=h*1.2+hbp, r=CR);
               };
           };
       };""",
        )
    end
end

function generateSVG(P::CoinProblem; folder::AbstractString = pwd())
    totalW = P.W + 2 * (P.margin + 0.1)
    totalH = P.H + 2 * (P.margin + 0.1)

    mx = (P.margin + 0.1) / totalW
    my = (P.margin + 0.1) / totalH

    set_default_graphic_size(totalW * 1.0mm, totalH * 1.0mm)
    composition = compose(context())
    for s in P.CS
        composition = compose(
            composition,
            (
                context(),
                Compose.text(s.x / totalW + mx, s.y / totalH + my, s.C.v),
                fontsize(6pt),
            ),
        )
        composition = compose(
            composition,
            (
                context(
                    (s.x - s.C.r) / totalW + mx,
                    (s.y - s.C.r) / totalH + my,
                    2 * s.C.r / totalW,
                    2 * s.C.r / totalH,
                ),
                circle(),
                fill("bisque"),
            ),
        )
    end
    composition = compose(
        composition,
        (context(mx, my, P.W / totalW, P.H / totalH), rectangle(), fill("tomato")),
    )
    composition |> SVG(folder * "/coins.SVG")
end

function CanadianCoins()
    C = Array{Coin,1}(undef, 0)
    C = vcat(C, Coin("Nickel", 10.6, 1.65, 5, 1, 0)) # Nickel
    C = vcat(C, Coin("Dime", 9.0, 1.15, 10, 1, 0)) # Dime
    C = vcat(C, Coin("Quarter", 11.95, 1.5, 25, 1, 0)) # Quarter
    C = vcat(C, Coin("Loonie", 13.30, 1.85, 100, 1, 0)) # Loonie
    C = vcat(C, Coin("Toonie", 14.0, 1.7, 200, 1, 0)) # Twonie
    return C
end

end
