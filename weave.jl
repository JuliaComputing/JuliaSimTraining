using Literate

const SCRIPT_PATH = @__DIR__
const STATIC_PATH = joinpath(SCRIPT_PATH, "_static")
scripts = Dict("01_JuliaHub" => [
                   "01_Interactive_Development.jl",
                   "02_Batch_Job.jl",
                   "03_Batch_Job_Logging.jl"],
               "02_JuliaSim" => [
                   "01_RC_Circuit_Model.jl",
                   "02_RLC_Parameter_Estimation.jl",
                   "03_Surrogate_from_ODE.jl",
                   "04_Surrogate_from_FMU.jl"])

isdir(STATIC_PATH) || mkpath(STATIC_PATH)

for (dir, files) in pairs(scripts)
    for file in files
        Literate.markdown(joinpath(dir, file), joinpath(STATIC_PATH, dir);
                          documenter = false)
    end
end
