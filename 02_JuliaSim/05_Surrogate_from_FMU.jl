# # Surrogates from FMUs
# This example demonstrates the process of creating a surrogate from an FMU.
# Creating surrogates from any input source involves the following steps:
# 1. Environment Setup
# 1. Problem Definition
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
using DataSets
using OrdinaryDiffEq
using Random

Random.seed!(1) # for reproducibility

# ## Problem Definition
# When **within JuliaSim IDE**: use the public DataSet.

open(io -> write(joinpath(@__DIR__, "CoupledClutches.fmu"), io),
     IO,
     dataset("jacob_vaverka2/CoupledClutches_ME_fmu"))

# Otherwise, **when unable to access JuliaHub DataSets**:
# Download the example FMU, [CoupledClutches](https://github.com/modelica/fmi-cross-check/blob/master/fmus/2.0/me/linux64/MapleSim/2018/CoupledClutches/CoupledClutches.fmu).
# Upload the file so that it can be accessed in your IDE.
# Place the FMU in the `JuliaSimTraining/Surrogates/` directory and match the name for `fmu_path`.

fmu_path = joinpath(@__DIR__, "CoupledClutches.fmu")
fmu = FMI.fmi2Load(fmu_path)

# ## Data Generation
# Now that the Julia environment and model are prepared, we need a mechanism to create experiment data.
# `ExperimentData` is the common input needed to train a surrogate model. In the most basic case,
# we create experiment data by executing many simulation runs with varying parameters values.
# These simulation results form an `ExperimentData` object which is a data structure that will be used
# in the training step.
#
# How we generate data is important because this data will be used to train the surrogate.
# Rather than manually executing simulation runs to generate data, we can simply describe the space we wish to sample
# and let `JuliaSimSurrogates` handle the process of executing runs and collecting results.
#
# Define the acceptable ranges for the parameters and the number of sample to generate.
# We also provide meaningful labels for later analysis.

nsamples_params = 250
params_lb = [0.19, 0.39]
params_ub = [0.21, 0.41]
param_space = ParameterSpace(params_lb, params_ub, nsamples_params;
                             labels = ["freqHz", "T2"])

# To aide in the process of generating this `ExperimentData`, or training data, we leverage the `SimulatorConfig`.
# This mechanism configures the simulations necessary to cover the desired sampling space.
# Below we define our simulation configuration using our sampling space.

simconfig = SimulatorConfig(param_space);
display_table(simconfig; compact = false)

# Now let's create our `ExperimentData` object and name it `ed`.
# We create `ed` by calling our `simconfig` as a function with our `fmu` as input.
# `simconfig` will then sample the space we described by running `fmu` with the proper configurations.

ed = simconfig(fmu; outputs = string.(FMI.FMIImport.fmi2GetOutputNames(fmu)));
display_table(ed; compact = false)

# ## Surrogate Creation
# Everything is in place to create a surrogate.
# We have a model, and we have experiment data. These two combined with a training algorithm form the final step.
# First we define the reservoir size (larger will typically lead to more accurate results at the expense of longer training times).
# Then we define `model` to be the CTESN algorithm.
# `JuliaSimSurrogates` has several algorithms to choose from, and the appropriate one depends on the particular engineering problem.
# This example uses the Continous-Time Echo State Network which was developed within JuliaHub and proves useful for non-linear, stiff systems.

RSIZE = 100
model = CTESN(RSIZE)
surrogate = surrogatize(ed, model; verbose = true);

# We have created our `surrogate` object! This can be called using a convention similar to the common SciML `solve` interface.
# Provide initial conditions, parameter values and timespan (`x0`, `p` and `t` respectively) to produce its result.
#
#   `surrogate(x0, p, t)`

surrogate([0.0, 1.0, 0.0, 0.0], [0.2002, 0.4004], (0, 1e4))

# ## Workflow
# A useful working paradigm is to train the surrogate once and use it for inference many times after.
# How do we fast-forward through the training step?

using JuliaHubClient
using Serialization

# Serialize the surrogate object and save the result as a DataSet on JuliaHub

Serialization.serialize(joinpath(@__DIR__, "coupled_clutches_surrogate.jls"), (; surrogate))
JuliaHubClient.upload_new_dataset("Coupled_Clutches_Surrogate",
                                  joinpath(@__DIR__, "coupled_clutches_surrogate.jls");
                                  tags = ["training", "workshop"],
                                  description = "Surrogate model from `CoupledClutches.fmu`")
