# [State estimation for ModelingToolkit models](https://help.juliahub.com/juliasimcontrol/stable/examples/state_estimation/)

using JuliaSimControl, ModelingToolkit
using ModelingToolkit, Plots, OrdinaryDiffEq, LinearAlgebra

@variables t
D = Differential(t)

function Mass(; name, m = 1.0, xy = [0., 0.], u = [0., 0.])
    ps = @parameters m=m
    sts = @variables pos(t)[1:2]=xy v(t)[1:2]=u
    eqs = collect(D.(pos) .~ v)
    ODESystem(eqs, t, [pos..., v...], ps; name)
end

function Spring(; name, k = 1e4, l = 1.)
    ps = @parameters k=k l=l
    @variables x(t), dir(t)[1:2]
    ODESystem(Equation[], t, [x, dir...], ps; name)
end

function connect_spring(spring, a, b)
    [
        spring.x ~ norm(collect(a .- b))
        collect(spring.dir .~ collect(a .- b))
    ]
end

spring_force(spring) = -spring.k .* collect(spring.dir) .* (spring.x - spring.l)  ./ spring.x

m = 1.0
xy = [1., -1.]
k = 1e4
l = 1.
center = [0., 0.]
g = [0., -9.81]
@named mass = Mass(m=m, xy=xy)
@named spring = Spring(k=k, l=l)

eqs = [
    connect_spring(spring, mass.pos, center)
    collect(D.(mass.v) .~ spring_force(spring) / mass.m .+ g)
]

@named _model = ODESystem(eqs, t, [spring.x; spring.dir; mass.pos], [])
@named model = compose(_model, mass, spring)
sys = structural_simplify(model)

prob = ODEProblem(sys, [], (0., 2.))
sol = solve(prob, Rosenbrock23())
plot(sol, layout=4, plot_title="Simulation")

# ## State Estimation

model = complete(model)
inputs = []
outputs = collect(model.mass.pos)
funcsys = FunctionSystem(model, inputs, outputs)
p = ModelingToolkit.varmap_to_vars(ModelingToolkit.defaults(model), funcsys.p)

Ts = 0.005 # Sample time
discrete_dynamics = JuliaSimControl.rk4(funcsys, Ts, supersample=2)

using LowLevelParticleFilters
Rdi = LowLevelParticleFilters.double_integrator_covariance(Ts, 1)
R1 = cat(Rdi, Rdi, dims=(1,2)) + 1e-9I
R2 = 0.005I(funcsys.ny)
x0 = sol(0, idxs=funcsys.x)
d0 = MvNormal(x0, R1)

Tf = sol.t[end]                     # Final time
timevec = 0:Ts:Tf
u = fill([], length(timevec))       # No inputs
y0 = sol(timevec, idxs=outputs).u   # Noise-free output
y = [y0[i] + rand(MvNormal(R2)) for i in 1:length(y0)] # Add measurement noise

ukf = UnscentedKalmanFilter(discrete_dynamics, R1, R2, d0; p)
filtersol = forward_trajectory(ukf, u, y)
plot(timevec, filtersol, ploty=false, plotx=false, plotu=false)
plot!(sol, idxs=funcsys.x, plot_title="State estimation using UKF")
plot!(timevec, reduce(hcat, y)', sp=[1 3], lab="Measurements", alpha=0.5)
