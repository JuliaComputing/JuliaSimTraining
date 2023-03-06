using JuliaSimSurrogates
using Random

using Distributed
rmprocs(workers())
addprocs(7, exeflags = ["--project=."])

@everywhere using DataGeneration.FMI
@everywhere using DataGeneration
@everywhere using OrdinaryDiffEq

Random.seed!(1)

fmu_path = "CoupledClutches.fmu"
fmu = FMI.fmi2Load(fmu_path)

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
param_space = ParameterSpace(p_lb, p_ub, nsamples_p; labels = ["freqHz", "T2"])

simconfig = SimulatorConfig(ic_space, ctrl_space, param_space)
display_table(simconfig; compact = false)

ed = simconfig(fmu)
display_table(ed; compact = false)

rmprocs(workers())

RSIZE = 100
model = CTESN(RSIZE)
surrogate = surrogatize(ed, model; verbose = true);
