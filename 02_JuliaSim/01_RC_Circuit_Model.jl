# # Building a Model
# JuliaSim is a suite of advanced features for simulation and modeling engineering workflows.
# Before diving into the JuliaSim capabilities, we need a model.
# This script walks through the steps to build a resistor–capacitor (RC) circuit,
# and will do so using `ModelingToolkit.jl` -
# _a modeling language for high-performance symbolic-numeric computation in scientific
# computing and scientific machine learning_[^mtk].

# ## RC Circuit Model Description
# > A resistor–capacitor circuit (RC circuit), or RC filter or RC network, is an electric
# > circuit composed of resistors and capacitors. It may be driven by a voltage or current
# > source and these will produce different responses. A first order RC circuit is composed
# > of one resistor and one capacitor and is the simplest type of RC circuit[^rc].

# ## Modeling Toolkit Standard Library
# The `Electrical` module of `ModelingToolkitStandardLibrary` contains all the
# components we need to build the simplest RC circuit described above.

using ModelingToolkit, OrdinaryDiffEq, Plots
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant

# Set starting values for resistance, current and voltage.

R = 1.0
C = 1.0
V = 1.0

# The independent variable to the system will be time.

@variables t

# Create each component from the standard library.
# These are `@named` models, which practically means that all model parameters and states
# belong to that model's namespace.
# This approach can help to avoid ambiguity when passing a symbolic default to a component.

@named resistor = Resistor(R = R)
@named capacitor = Capacitor(C = C)
@named source = Voltage()
@named constant = Constant(k = V)
@named ground = Ground()

#=
All components (or models) exist. Now they must be properly connected.
Use the diagram to form the appropirate connections.

```
      I
     ──────►
    ┌──────────────┐
  ──┴──          ┌─┴─┐
C  ─┬─           │   │ R
    │            └─┬─┘
    └──────────────┘
```
=#

# > **Tip**
# > Use the documentation to get information on each components description, states,
# > parameters and connectors.

rc_eqs = [connect(constant.output, source.V)
          connect(source.p, resistor.p)
          connect(resistor.n, capacitor.p)
          connect(capacitor.n, source.n, ground.g)]

# Composing the entire system requires the connection and the component systems themselves.

@named rc_model = ODESystem(rc_eqs, t,
                            systems = [resistor, capacitor, constant, source, ground])

# > **Tip**
# > An equivalent method to create the system is to use `compose`.
# > ```julia
# > @named _rc_model = ODESystem(rc_eqs, t)
# > @named rc_model = compose(_rc_model, [resistor, capacitor, constant, source, ground])
# > ```

# The resulting model is comprised of many equations.

equations(expand_connections(rc_model))

# However, we know the system has a more simple description.
# Watch what happens when `structural_simplify` is used to algebraically simplify the system's equations.

sys = structural_simplify(rc_model)

# The system is reduced to a single equation - that of an ideal capacitor.

equations(sys)

# Define a differential-algebraic equation problem of the system.

prob = ODAEProblem(sys, Pair[], (0, 10.0))

# Solve the problem using the common solve interface.

sol = solve(prob, Tsit5())

# Plot the results. Note that accessing the desired variables is done via its model namespace.

plot(sol, idxs = [capacitor.v, resistor.i],
     title = "RC Circuit Demonstration",
     labels = ["Capacitor Voltage" "Resistor Current"])

# [^mtk]: [ModelingToolkit.jl: High-Performance Symbolic-Numeric Equation-Based Modeling](https://docs.sciml.ai/ModelingToolkit/stable/#ModelingToolkit.jl:-High-Performance-Symbolic-Numeric-Equation-Based-Modeling)
# [^rc]: [RC Circuit](https://en.wikipedia.org/wiki/RC_circuit)
