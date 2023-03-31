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

# The `ModelingToolkitStandardLibrary` contains all the components we need to build the
# simplest RC circuit described above. The model  is outlined by the diagram below.

#=
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

using ModelingToolkit, OrdinaryDiffEq, Plots
using ModelingToolkitStandardLibrary.Electrical
using ModelingToolkitStandardLibrary.Blocks: Constant

# Constants

R = 1.0
C = 1.0
V = 1.0

# Independent time variable

@variables t

# Components

@named resistor = Resistor(R = R)
@named capacitor = Capacitor(C = C)
@named source = Voltage()
@named constant = Constant(k = V)
@named ground = Ground()

# Connections

rc_eqs = [connect(constant.output, source.V)
          connect(source.p, resistor.p)
          connect(resistor.n, capacitor.p)
          connect(capacitor.n, source.n, ground.g)]

# System

@named rc_model = ODESystem(rc_eqs, t,
                            systems = [resistor, capacitor, constant, source, ground])
@show equations(rc_model)

# Simplified system

sys = structural_simplify(rc_model)
@show equations(sys)

# Problem

prob = ODAEProblem(sys, Pair[], (0, 10.0))

# Solve

sol = solve(prob, Tsit5())
plot(sol, vars = [capacitor.v, resistor.i],
     title = "RC Circuit Demonstration",
     labels = ["Capacitor Voltage" "Resistor Current"])

# [^mtk]: [ModelingToolkit.jl: High-Performance Symbolic-Numeric Equation-Based Modeling](https://docs.sciml.ai/ModelingToolkit/stable/#ModelingToolkit.jl:-High-Performance-Symbolic-Numeric-Equation-Based-Modeling)
# [^rc]: [RC Circuit](https://en.wikipedia.org/wiki/RC_circuit)
