using JuliaSimSurrogates
using OrdinaryDiffEq
using Random

Random.seed!(1)

"Lotkva Volterra"
function lv(u, p, t)
    u₁, u₂ = u
    α, β, γ, δ = p
    dx = α * u₁ - β * u₁ * u₂
    dy = δ * u₁ * u₂ - γ * u₂
    [dx, dy]
end

# Specifying Base ODEProblem
p = [1.75, 1.8, 2.0, 1.8]
u0 = [1.0, 1.0]
tspan = (0.0, 12.5)
prob = ODEProblem{false}(lv, u0, tspan, p)

# Number of samples
nsamples_p = 2000

# Upper and lower bound of parameter space
p_lb = [1.5,1.75,1.5,1.75]
p_ub = [2.5,2.0,2.5,2.0]

# Setup the sample space to run simulations from
# Only using ParameterSpace but also have ICSpace and CtrlSpace
simconfig = SimulatorConfig(ParameterSpace(p_lb, p_ub, nsamples_p))
display_table(simconfig; compact=false)

# Run and collect simulations
ed = simconfig(prob; alg = Tsit5())
display_table(ed; compact=false)

# Basic hyperparameter for the CTESN
RSIZE = 100
model = CTESN(RSIZE);

# Generate surrogate
surrogate = surrogatize(ed, model; verbose = true);
