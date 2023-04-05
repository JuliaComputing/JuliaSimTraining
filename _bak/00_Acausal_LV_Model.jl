# # Acausal Modeling with `ModelingToolkit.jl`
# ModelingToolkit is a flxible modeling framework for writing and conducting simulations in Julia.
# This section introduces the basics of the framework.
#
# ## What is `ModelingToolkit.jl`?
# > ModelingToolkit.jl is a symbolic-numeric modeling package.
# > Thus it combines some of the features from symbolic computing packages like SymPy or Mathematica
# > with the ideas of equation-based modeling systems like the causal Simulink and the acausal Modelica.
# > It bridges the gap between many different kinds of equations, allowing one to quickly and easily
# > transform systems of DAEs into optimization problems, or vice-versa, and then simplify and parallelize
# > the resulting expressions before generating code.
# >
# > --- [MTK docs | Feature Summary](https://docs.sciml.ai/ModelingToolkit/stable/#Feature-Summary)
#
# | Module | Description |
# | :----- | :---------- |
# | ModelingToolkit.jl |	The symbolic modeling environment |
# | DifferentialEquations.jl |	The differential equation solvers |
# | Plots.jl |	The plotting and visualization package |

using ModelingToolkit, Plots, DifferentialEquations

# ## Define Parameters and Variables
# `t` is our independent variable. `x(t)` and `y(t)` are our state variables.
# All variables are defined using the `@variables` macro.
# All parameters are defined using the `@parameters` macro.
# Our differential term is defined w.r.t. `t`.

@variables t x(t) y(t)
@parameters α β δ γ
D = Differential(t)

# ## Define a System
# No need to define a function.
# Our terms can be used to describe our equations.

eqs = [D(x) ~ α * x - β * x * y
       D(y) ~ δ * x * y - γ * y];

# These equations can be turned into a system of equations with independent variable `t`.

@named model = ODESystem(eqs, t);

# ## Define a Problem
# We now want to take our symbolic system of equations and create a numeric problem.
# This numeric problem is what we wish to simulate.
# In order to create the problem, provide the model, all initial conditions, the simulation timespan and parameter values.

prob = ODEProblem(model, [x => 0.9, y => 1.8], (0, 20.0),
                  [α => 2 / 3, β => 4 / 3, γ => 1, δ => 1])

# ## Solve the Problem
# Time to solve the problem!

sol = solve(prob)

# Plot recipes are automatically available for solutions, so it is easy to visualize results.

plot(sol)

# ## Next Steps
# Write your first component-based model of a RLC circuit in
# `JuliaSimTraining/02_JuliaSim/02_Acausal_RLC_Model.jl`.
