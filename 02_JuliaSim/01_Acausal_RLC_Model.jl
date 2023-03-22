# # Acausal RLC Model
# Build and simulate an acausal model from scratch using ModelingToolkit.
# The components necessary to build the model are defined within a module.
# Modules help separate code by their distinct purpose.
# The module `RLC` is defined in the same file where it is used, but in practice this module can be called from another file.

module RLC

using ModelingToolkit

@variables t
@connector function Pin(; name)
    sts = @variables v(t) = 1.0 i(t) = 1.0 [connect = Flow]
    return ODESystem(Equation[], t, sts, []; name=name)
end

function Ground(; name)
    @named g = Pin()
    eqs = [g.v ~ 0]
    return compose(ODESystem(eqs, t, [], []; name=name), g)
end

function OnePort(; name)
    @named p = Pin()
    @named n = Pin()
    sts = @variables v(t) = 1.0 i(t) = 1.0
    eqs = [
        v ~ p.v - n.v
        0 ~ p.i + n.i
        i ~ p.i
    ]
    return compose(ODESystem(eqs, t, sts, []; name=name), p, n)
end

function Resistor(; name, R=1.0)
    @named oneport = OnePort()
    @unpack v, i = oneport
    ps = @parameters R = R
    eqs = [v ~ i * R]
    return extend(ODESystem(eqs, t, [], ps; name=name), oneport)
end

function Capacitor(; name, C=1.0)
    @named oneport = OnePort()
    @unpack v, i = oneport
    ps = @parameters C = C
    D = Differential(t)
    eqs = [D(v) ~ i / C]
    return extend(ODESystem(eqs, t, [], ps; name=name), oneport)
end

function Inductor(; name, L=1.0)
    @named oneport = OnePort()
    @unpack v, i = oneport
    ps = @parameters L = L
    D = Differential(t)
    eqs = [D(i) ~ v / L]
    return extend(ODESystem(eqs, t, [], ps; name=name), oneport)
end

function ConstantVoltage(; name, V=1.0)
    @named oneport = OnePort()
    @unpack v = oneport
    ps = @parameters V = V
    eqs = [V ~ v]
    return extend(ODESystem(eqs, t, [], ps; name=name), oneport)
end

end

# ## Using Comonents to Build a Model
# Access the custom components by loading the `RLC` module (the preceeding dot in `.RLC` exists because the module is loaded from the same file).
# Load all other packages into the local scope (note that `ModelingToolkit` is loaded again outside the module definition).

using .RLC
using ModelingToolkit, Plots, DifferentialEquations

# Each custom component defined in `RLC` represents an `ODESystem`.
# Create instances of each custom component required to build the model as seen in the diagram.

L = C = V = R = 1.0

#-

@named inductor = RLC.Inductor(; L=L)
@named resistor = RLC.Resistor(; R=R)
@named capacitor = RLC.Capacitor(; C=C)
@named source = RLC.ConstantVoltage(; V=V)
@named ground = RLC.Ground()

# Once all required components are created, connect them such that the desired flow describes the circuit model.

rlc_eqs = [
    connect(source.p, resistor.p)
    connect(resistor.n, inductor.p)
    connect(inductor.n, capacitor.p)
    connect(capacitor.n, source.n)
    connect(capacitor.n, ground.g)
]

# Create a new model out of the collection of equations defined by the flow connections.

@named _rlc_model = ODESystem(rlc_eqs, t)

# Create a new model out of the characteristics and relationships of all components and their connections.

@named rlc_model = compose(_rlc_model, [inductor, resistor, capacitor, source, ground])

# Simplify this model into smallest and most performant code for simulation.

sys = structural_simplify(rlc_model)

# Define a problem with particular initial condition and parameter values of interest to simulate.

u0 = [capacitor.v => 0.0]
prob = ODEProblem(sys, u0, (0, 10.0))

# Solve the problem.

sol = solve(prob)

# Plot the result.

plot(sol)
