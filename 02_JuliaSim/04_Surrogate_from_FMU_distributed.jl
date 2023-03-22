# # Surrogates from FMUs
# This example demonstrates the process of creating a surrogate from an FMU using `Distributed.jl`.
# The same general steps will be followed:
# 1. Environment Setup
# 1. Problem Definition
# 1. Data Generation
# 1. Surrogate Creation

# ## Environment Setup
# The data generation process is very parallelizable.
# Therefore, each worker node must be configured with an environment to generate data.
# Results will then be collected on the main node for training.
#
# First, load the JuliaSimSurrogates package to make the DataGeneration modules available.

using JuliaSimSurrogates
using Random

# Then, load `Distributed.jl` in order to setup the proper environment on all workers.
# Ensure to add the desired number of worker processes and activate the environment.

using Distributed
rmprocs(workers())
addprocs(7; exeflags=["--project=."])

# Now make the packages for data generation available on all worker nodes.

@everywhere using DataGeneration.FMI
@everywhere using DataGeneration
@everywhere using OrdinaryDiffEq

Random.seed!(1) # for reproducibility

# ## Problem Definition
# When **within JuliaSim IDE**: use the public DataSet.

open(
    io -> write(joinpath(@__DIR__, "CoupledClutches.fmu"), io),
    IO,
    dataset("jvaverka2/CoupledClutches_fmu"),
)

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
# All three sampling spaces are described below:
# - Initial conditions space: `ICSpace`
# - Control space: `CtrlSpace`
# - Parameter space: `ParameterSpace`

nsamples_x0 = 3
x0_lb = vcat(0.0, 1.0, zeros(16))
x0_ub = vcat(0.2, 1.2, fill(0.2, 16))
ic_space = ICSpace(x0_lb, x0_ub, nsamples_x0)

nsamples_ctrl = 4
ctrl_lb = [0.0]
ctrl_ub = [0.2]
@everywhere func(u, p, t) = p * exp(-t)
ctrl_space = CtrlSpace(ctrl_lb, ctrl_ub, func, nsamples_ctrl)

nsamples_p = 5
p_lb = [0.19, 0.39]
p_ub = [0.21, 0.41]
param_space = ParameterSpace(p_lb, p_ub, nsamples_p; labels=["freqHz", "T2"])

# A simulator configuration composed of all three sampling spaces provides the most robust data generation method.

simconfig = SimulatorConfig(ic_space, ctrl_space, param_space);
display_table(simconfig; compact=false)

# Call the simulator configuration with our probem - in this case it is the FMU.

ed = simconfig(fmu; outputs=string.(FMI.FMIImport.fmi2GetOutputNames(fmu)));
display_table(ed; compact=false)

# Additional worker proessors can be removed at this point.

rmprocs(workers())

# ## Surrogate Creation
# Now use a surrogate model which supports simulator configurations comprised of all three sampling spaces - Augmented ELM.

RSIZE = 100
model = AugmentedELM(6, RSIZE)
surrogate = surrogatize(ed, model; verbose=true);

# Call the new surrogate!

surrogate(vcat(0.0, 1.0, zeros(2)), [0.2, 0.4], (0, 1e5))
