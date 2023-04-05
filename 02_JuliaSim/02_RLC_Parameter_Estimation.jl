# # [Uncertainty-Aware Parameter Estimation of an Acausal Circuit Model](https://help.juliahub.com/jsmo/dev/example/ChuaCircuit/#chua_circuit)
# How can does one perform parameter estimation with ModelingToolkit models?
# JuliaSim ModelOptimizer provides tools to complete this process in a robust manner
# with uncertainty awareness.
#
# JuliaSim ModelOptimizer can be seamlessly integrated with custom components
# generated through the Modeling Toolkit Standard Library.
# The Chua Circuit electrical model is the first example we are exploring in this integration.
# Let us have a look at the sections below.

using JuliaSimModelOptimizer
using OrdinaryDiffEq
using ModelingToolkit
using DataFrames
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Electrical: OnePort
using IfElse: ifelse
using Statistics
using StatsPlots

# ## Model Setup
# Create a custom component (non-linear resistor) using pre-defined components from
# the `Electrical` module of `ModelingToolkitStandardLibrary`. This strategy show how component
# libraries may be built up, extended and used to create more complicated models.

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

# Connections will determine the flow of electricity throughout the system.

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

# It is easy to generate the most performant system by calling `structural_simplify`.
# This allows us to define the model intuitively and still get out the most performan system.

sys = structural_simplify(model)

# As before, we can setup the problem and solve.

prob = ODEProblem(sys, Pair[], (0, 5e4), saveat = 100)
sol = solve(prob, Rodas4());

# ## Creating an Inverse Problem
# Defining the inverse problem consists of:
# - Specifying the parameters to optimize,
# - Specifying the search space to opimize over,
# - Defining the data collection to fit to,
# - Defining the collection of experiments to setup for the multi-simulation optimization problem.

data = DataFrame(sol);
trial = Trial(data, sys, tspan = (0, 5e4));
invprob = InverseProblem([trial], sys,
                         [Ro.R => (9.5e-3, 13.5e-3), C1.C => (9, 11), C2.C => (95, 105)]);

# ## Visualizing Opimized Parameters
# Plausible populations are generated using the `vpop` function on an `InverseProblem`.
# The result of a `vpop` is a set of parameters which sufficiently fit all trials to their
# respective data simultaniously. In this example, we have 3 parameters which are simultaneously optimized:
# the resistance of the resistor `Ro` and the capacitances of the capacitors `C1`, `C2`.

vp = vpop(invprob, StochGlobalOpt(maxiters=10), population_size = 50)
params = DataFrame(vp)

# Once the parameters have been optimized, we can use the statistical plotting
# libraries of Julia to generate density plots of the parameters.
# We can then compare the mean value of these density plots with the original parameter values.

p1 = density(params[:,1], label = "Estimate: Ro")
plot!([12.5e-3,12.5e-3],[0.0, 300],lw=3,color=:green,label="True value: Ro",linestyle = :dash);

p2 = density(params[:,2], label = "Estimate: C1")
plot!([10,10],[0.0, 1],lw=3,color=:red,label="True value: C1",linestyle = :dash);

p3 = density(params[:,3], label = "Estimate: C2")
plot!([100,100],[0.0, 0.15],lw=3,color=:purple,label="True value: C2",linestyle = :dash);

l = @layout [a b c]
plot(p1, p2, p3, layout = l)
