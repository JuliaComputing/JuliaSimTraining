# [Modeling for control using ModelingToolkit](https://help.juliahub.com/juliasimcontrol/stable/examples/mtk_control/)

using ModelingToolkit, OrdinaryDiffEq, Plots, LinearAlgebra
using ModelingToolkitStandardLibrary.Mechanical.Rotational
using ModelingToolkitStandardLibrary.Blocks: Sine
using ModelingToolkit: connect
import ModelingToolkitStandardLibrary.Blocks
t = Blocks.t

# Parameters
m1 = 1
m2 = 1
k = 1000 # Spring stiffness
c = 10   # Damping coefficient

@named inertia1 = Inertia(; J = m1)
@named inertia2 = Inertia(; J = m2)

@named spring = Spring(; c = k)
@named damper = Damper(; d = c)

@named torque = Torque()

function SystemModel(u=nothing; name=:model)
    eqs = [
        connect(torque.flange, inertia1.flange_a)
        connect(inertia1.flange_b, spring.flange_a, damper.flange_a)
        connect(inertia2.flange_a, spring.flange_b, damper.flange_b)
    ]
    if u !== nothing
        push!(eqs, connect(torque.tau, u.output))
        return @named model = ODESystem(eqs, t; systems = [torque, inertia1, inertia2, spring, damper, u])
    end
    ODESystem(eqs, t; systems = [torque, inertia1, inertia2, spring, damper], name)
end

model = SystemModel(Sine(frequency=30/2pi, name=:u))
sys = structural_simplify(model)
prob = ODEProblem(sys, Pair[], (0.0, 1.0))
sol = solve(prob, Rodas5())
plot(sol)
