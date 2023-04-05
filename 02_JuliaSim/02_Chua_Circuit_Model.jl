# # Custom Model Components
# What happens when the standard library is missing a component?
# For instance, say we want to build a Chua circuit model.
# We would need to build a nonlinear resistor to build such a system.

using OrdinaryDiffEq
using ModelingToolkit
using DataFrames
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Electrical: OnePort
using IfElse: ifelse
using Statistics
using StatsPlots

# ## Buidling the Nonlinear Resistor
# Here is an image of the circuit we wish to build.

# ![chua](../../_assets/chua.png)

# The component labeled ``N_R`` is the nonlinear resistor which we need to build based off
# the current-voltage characteristics in the following diagram.

# ![nr](../../_assets/diode-char-curve.png)

@parameters t

function NonlinearResistor(; name, Ga, Gb, Ve)
    @named oneport = OnePort()
    @unpack v, i = oneport
    pars = @parameters Ga=Ga Gb=Gb Ve=Ve
    eqs = [
        i ~ ifelse(v < -Ve,
                   Gb * (v + Ve) - Ga * Ve,
                   ifelse(v > Ve,
                          Gb * (v - Ve) + Ga * Ve,
                          Ga * v)),
    ]
    extend(ODESystem(eqs, t, [], pars; name = name), oneport)
end

# ## Building the Model
# Between the pre-defined components available from `ModelingToolkitStandardLibrary.Electrical`
# and our custom component, we have all the required pieces to define our model.

@named L = Inductor(L = 18)
@named Ro = Resistor(R = 12.5e-3)
@named G = Conductor(G = 0.565)
@named C1 = Capacitor(C = 10, v_start = 4)
@named C2 = Capacitor(C = 100)
@named Nr = NonlinearResistor(Ga = -0.757576,
                              Gb = -0.409091,
                              Ve = 1)
@named Gnd = Ground()

# For connections to determine the flow of electricity throughout the system.

connections = [connect(L.p, G.p)
               connect(G.n, Nr.p)
               connect(Nr.n, Gnd.g)
               connect(C1.p, G.n)
               connect(L.n, Ro.p)
               connect(G.p, C2.p)
               connect(C1.n, Gnd.g)
               connect(C2.n, Gnd.g)
               connect(Ro.n, Gnd.g)]

# These connections along with their internal systems come together to form the model.

@named model = ODESystem(connections, t, systems = [L, Ro, G, C1, C2, Nr, Gnd])
equations(expand_connections(model))

# It is easy to generate the most performant system by calling `structural_simplify`.
# This allows us to define the model intuitively and still get out the most performan system.

sys = structural_simplify(model)
equations(sys)

# As before, we can setup the problem and solve.

prob = ODEProblem(sys, Pair[], (0, 5e4), saveat = 100)
sol = solve(prob, Rodas4());
plot(sol)
