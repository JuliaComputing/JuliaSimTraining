# # Running Batch Jobs on JuliaHub
# The JuliaHub extension makes it easy to scale your simulations by leveraging cloud compute.
# For instance, say we want to run our model over a longer timespan but do not want to wait for the simulation to complete.
# We can kickoff a batch job on JuliaHub to execute the simulation, and we can view the logs for the job at a later date.
# To get started, navigate to the JuliaHub extension by clicking the JuliaHub logo on the left-most sidebar
# (or by using the command palette, `CTRL + SHIFT + P`, and executing the `View: Show JuliaHub` command).
#
# ## JuliaHub Extension Overview
# The basic sections of the JuliaHub extension can be summarized as follows:
# - **Julia script**: the code to execute
# - **Bundle directory**: the directory containing any and all files necessary for successful execution
# - **Compute configuration**: specifications for the compute environment to use for execution
#   - Should the run occur on a _single-process_ or _distributed_?
#   - Should the run occur on _CPUs_ or _GPUs_?
#   - How powerful should each machine be?
# - **Number of Nodes**: the total number of machines to use for execution
# - **Limit**: the maximum time or cost limit should the code run longer than expected
# - **Image options**: the environment to use for execution (`Default` is a standard Julia environment while `JuliaSim` contains all proprietary JuliaSim packages)
# - **Job name**: a descriptive name to identify the job
# - **Inputs**: any input values expected by the _Julia script_.
#
# ## JuliaHub Example Run
# To run this example, follow the steps below:
# 1. Open this file (`JuliaSimTraining/01_JuliaHub/02_Batch_Job.jl`) in the editor
# 1. Navigate to the JuliaHub extension
# 1. **Julia script**: click _Use current file_
# 1. **Bundle**: do nothing
# 1. **Compute configuration**: Start a `distributed` `CPU` job with `8` vCPUs per node and `4` GB of memory per vCPU with one Julia process for each `vCPU`.
# 1. **Number of Nodes**: set to `1`
# 1. **Limit**: do nothing
# 1. **Image options**: select `JuliaSim`
# 1. **Job name**: enter `<your name> first batch job`
# 1. **Inputs**: do nothing
# 1. Click **Start Job**!

using ModelingToolkit, Plots, DifferentialEquations

@variables t x(t) y(t)
@parameters α β δ γ
D = Differential(t)
eqs = [
    D(x) ~ α * x - β * x * y
    D(y) ~ δ * x * y - γ * y
];

@named model = ODESystem(eqs, t);

prob = ODEProblem(
    model, [x => 0.9, y => 1.8], (0, 3600.0), [α => 2 / 3, β => 4 / 3, γ => 1, δ => 1]
)

sol = solve(prob)
plot(sol)

# ## Next Steps
# You have the basic knowledge required to run batch jobs on JuliaHub.
# In the next exercise (`JuliaSimTraining/01_JuliaHub/03_Batch_Job_Logging.jl`), you'll learn about the rich logging features of JuliaHub.