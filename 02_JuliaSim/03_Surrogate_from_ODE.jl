# # Surrogates from an ODE
# JuliaSimSurrogates is a package to help standardize the process of creating surrogate models across engineering domains.
# The steps below are common for creating surrogates from various starting points:
#
# 1. Environment Setup
# 1. Problem Definition
# 1. Data Generation
# 1. Surrogate Creation
#
# This document walks through the process of creating a surrogate from an ODE.
#
# ## Environment Setup
# To begin, load the necessary packages.

using JuliaSimSurrogates
using OrdinaryDiffEq
using Random

Random.seed!(1) # for reproducibility

# ## Problem Definition
# This example defines the problem as an `ODEProblem`.

"Lotkva Volterra"
function lv(u, p, t)
    u₁, u₂ = u
    α, β, γ, δ = p
    dx = α * u₁ - β * u₁ * u₂
    dy = δ * u₁ * u₂ - γ * u₂
    return [dx, dy]
end

# Define the parameters, initial conditions and timespan to create the problem.

p = [1.75, 1.8, 2.0, 1.8]
u0 = [1.0, 1.0]
tspan = (0.0, 12.5)

# It is important here that the problem is explicitly defined as out-of-place.
# The reason for this is due to the surrogate training algorithm.

prob = ODEProblem{false}(lv, u0, tspan, p) # `{false}` indicates this problem is out-of-place.

# ## Data Generation
# Before training a surrogate, we first need training data.
# When working with an ODE, we generate synthetic data by simulating the model and using that collection of runs for training.
#
# Declare the number of samples to generate.

nsamples_p = 2_000

# Declare the upper and lower bound for the parameters.
# These bounds describe the parameter space to be explored throughout the number of samples.

p_lb = [1.5, 1.75, 1.5, 1.75]
p_ub = [2.5, 2.0, 2.5, 2.0]

# Define a configuration which will run simulations over the described sample space until the desired number of samples is reached.
# JuliaSimSurrogates provides methods to display the summary of a simulator configuration as a formatted table.

simconfig = SimulatorConfig(ParameterSpace(p_lb, p_ub, nsamples_p))
display_table(simconfig; compact = false)

# The simulator configuration can now be called to run the various simulation setups against the given problem.
# Keyword arguments such as the solver algorithm, `alg`, are supported.
# All simulation runs are gathered into an `ExperimentData` object (assigned to `ed`).
# Again, JuliaSimSurrogates provides methods to display summary information for a collection of experiment data.

ed = simconfig(prob; alg = Tsit5())
display_table(ed; compact = false)

# ## Surrogate Creation
# Now that the experiment data object is ready, we are almost ready to create a surrogate model.
# First, declare the reservoir size to use during training.
# This example uses a relatively small number of 100.
# In practice engineers may increase this value in intervals (e.g. jumps of 5-20 at a time) and assess the improvement in accuracy with each increase.

RSIZE = 100

# Then chose the surrogate training model.
# The CTESN is a JuliaSim solution which performs well on stiff, non-linear systems.
# However, there are other training models available such as ELM, AugmentedELM, and others.
# Ask the JuliaSim team if you need further assistance in choosing the right surrogate model for your problem.

model = CTESN(RSIZE);

# Finally, we are ready to generate the surrogate.

surrogate = surrogatize(ed, model; verbose = true);

# This `surrogate` object can now be called just as you would call `solve` on a typical ODE problem.
# However, now you are calling the semi-neural ODE which has been trained over the total sample space using CTESN!

surrogate([1.0, 1.0], [2.0, 1.85, 2.0, 1.85], (0, 1e6))
