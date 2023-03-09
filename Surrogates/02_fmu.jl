# # Surrogates from FMUs
# This example demonstrates the process of creating a surrogate from an FMU.
# Creating surrogates from any input source involves the following steps:
# 1. Julia Environment Setup
# 1. Model Setup
# 1. Data Generation
# 1. Surrogate Creation

# ## Julia Environment Setup
# The `JuliaSimSurrogates` package along with its `DataGeneration` submodule
# provide a consistent interface for creating surrogates from FMUs as well as ODE systems.
# Below, we ensure to load the `DataGeneration.FMI` module which will provide the necessary
# tools for working with FMUs.

using JuliaSimSurrogates
using DataGeneration.FMI
using DataGeneration
# TODO: remove if unecessary
using OrdinaryDiffEq
using Random

Random.seed!(1)

# ## Model Setup
# Download the example FMU, [CoupledClutches](https://github.com/modelica/fmi-cross-check/blob/master/fmus/2.0/me/linux64/MapleSim/2018/CoupledClutches/CoupledClutches.fmu).
# Upload the file so that it can be accessed on JuliaHub using the IDE.
# Place the FMU in the `JuliaSimTraining/Surrogates/` directory and match the name for `fmu_path`.

fmu_path = joinpath(@__DIR__, "CoupledClutches_ME.fmu")
fmu = FMI.fmi2Load(fmu_path)

# ## Data Generation
# Now that the Julia environment and model are prepared, we need a mechanism to create experiment data.
# `ExperimentData` is the common input needed to train a surrogate model. We create experiment data by
# executing many simulation runs with varying initial conditions, parameters and control values.
# These simulation results form an `ExperimentData` object which is a data structure which will be used
# in the training step.

# ### Sampling Spaces
# How we generate data is important because this data will be used to train the surrogate.
# Rather than manually executing simulation runs to generate data, we can simply describe the space we wish to sample
# and let `JuliaSimSurrogates` handle the process of executing runs and collecting results.

# #### Initial Conditions Space
# Define the acceptable ranges for the initial conditions and the number of sample to generate.
# Remember to describe the various conditions which your surrogate model may encounter in production.

nsamples_x0 = 3
x0_lb = vcat(0.0, 1.0, zeros(16))
x0_ub = vcat(0.2, 1.2, fill(0.2, 16))
ic_space = ICSpace(x0_lb, x0_ub, nsamples_x0)

# #### Control Space
# Define the acceptable ranges for the model controls and the number of sample to generate.
# This space takes a function as input along with the bounds and number of samples.

nsamples_ctrl = 4
ctrl_lb = [0.0]
ctrl_ub = [0.2]
func(u, p, t) = p * exp(-t)
ctrl_space = CtrlSpace(ctrl_lb, ctrl_ub, func, nsamples_ctrl)

# #### Parameter Space
# Define the acceptable ranges for the parameters and the number of sample to generate.
# We also provide meaningful labels for later analysis.

nsamples_p = 5
p_lb = [0.19, 0.39]
p_ub = [0.21, 0.41]
param_space = ParameterSpace(p_lb, p_ub, nsamples_p; labels = ["freqHz", "T2"])

# ### Simulator Configurations
# To aide in the process of generating this `ExperimentData`, or training data, we leverage `SimulatorConfig`.
# This mechanism configures the simulations necessary to cover the desired sampling space.
# One, two or all three sampling spaces can be used to declare a `SimulatorConfig`.
# Let's look at an example where we use all three spaces.

simconfig = SimulatorConfig(ic_space, ctrl_space, param_space)
display_table(simconfig; compact = false)

# ### Experiment Data

ed = simconfig(fmu)
display_table(ed; compact = false)

# ## Surrogate Creation
# We now have everything we need to create our surrogate.
# We have a model, and we have experiment data. These two combined with a training model come together for the final step.
# First we define the reservoir size to use (larger will typically lead to more accurate results at the expense of longer training times).
# Then we decide which training model to use.
# `JuliaSimSurrogates` has several models to choose from, and the appropriate model depends on the particular engineering problem.
# This example uses the Continous-Time Echo State Network which was developed within JuliaHub and proves useful for non-linear, stiff systems.

RSIZE = 10
model = CTESN(RSIZE)
surrogate = surrogatize(ed, model; verbose = true);

# We now have a `surrogate` object which can be called using a convention similar to the common SciML `solve` interface.

surrogate()