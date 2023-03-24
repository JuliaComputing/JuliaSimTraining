# # Interactive Development with JuliaSim
# JuliaSim IDE is the interactive development environment for working with JuliaSim.
# To get started, login to <juliahub.com> and click **launch** on JuliaSim IDE (if JuliaSim IDE does not appear on the home page then go to <juliahub.com/ui/Applications>).
# JuliaHub will spin up a JuliaSim IDE for you. Once it is ready simply click **connect**.
#
# ## What is JuliaSim IDE?
# In essence, JuliaSim IDE is VS Code in a web browser plus a precompiled environment suited for simulation and modeling.
# This environment contains common packages for modeling such as `ModelingToolkit.jl`, `Plots.jl` and `DifferentialEquations.jl`.
# All JuliaSim packages are also available in the environment and can be accessed like any other package by the `using` keyword.
#
# ## Loading Packages
# This example requires three packages; load them by executing the line below.

using ModelingToolkit, Plots, DifferentialEquations

# ## Executing Code
# - `CTRL + ENTER`: sends current line to REPL
# - `SHIFT + ENTER`: sends current line to REPL and moves to the next line
# Execute the lines below to declare the variables, parameters and differential for this example.

@variables t x(t) y(t)
@parameters α β δ γ
D = Differential(t)

# ## Executing Code Cells
# The Julia VS Code extension allows us to group lines of code together into _cells_.
# When working interactively, code cells conveniently allow users to execute related lines of code together.
# Use any one of the following to delineate code cells:
# - `#-`
# - `##`
# - `#%%`
# `ALT + ENTER` executes the current code cell.
# `SHIFT + ALT + ENTER` executes the current code cell and moves to the next cell.
# Use the code cells below for practice.

#-

eqs = [D(x) ~ α * x - β * x * y
       D(y) ~ δ * x * y - γ * y];
@named model = ODESystem(eqs, t);

prob = ODEProblem(model, [x => 0.9, y => 1.8], (0, 20.0),
                  [α => 2 / 3, β => 4 / 3, γ => 1, δ => 1])
#-
sol = solve(prob)
#-
plot(sol)

# ## Next Steps
# You have now performed some interactive work in JuliaSim IDE.
# The Julia VS Code extension offers many more [keybindings & commands](https://www.julia-vscode.org/docs/stable/userguide/keybindings/) that can improve your productivity in JuliaSim IDE.
# In the next exercise (`JuliaSimTraining/01_JuliaHub/02_Batch_Job.jl`), you'll learn how to run batch jobs on JuliaHub.
