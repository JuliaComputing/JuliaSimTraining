# # Acausal Modeling with `ModelingToolkit.jl`
# 
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
# Load ModelingToolkit to get started.

using ModelingToolkit, Plots, DifferentialEquations

# ## Define Parameters and Variables
# TODO

@variables t x(t) y(t)
@parameters α β δ γ
D = Differential(t)

# ## Define a System
# TODO

eqs = [D(x) ~ α * x - β * x * y
       D(y) ~ δ * x * y - γ * y];
@named model = ODESystem(eqs, t);

# ## Define a Problem
# TODO

prob = ODEProblem(model, [x => 0.9, y => 1.8], (0, 20.0),
                  [α => 2 / 3, β => 4 / 3, γ => 1, δ => 1])

# ## Solve the Problem
# TODO

sol = solve(prob)
plot(sol)

# ## Next Steps
# Write your first component-based model of a RLC circuit in
# `JuliaSimTraining/02_JuliaSim/02_Acausal_RLC_Model.jl`.
