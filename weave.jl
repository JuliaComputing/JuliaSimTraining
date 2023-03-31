using Literate

const SCRIPT_PATH = @__DIR__
const STATIC_PATH = joinpath(SCRIPT_PATH, "_static")
scripts = Dict("01_JuliaHub" => [
                         "01_Interactive_Development.jl",
                         "02_Batch_Job.jl",
                         "03_Batch_Job_Logging.jl"],
                     "02_JuliaSim" => [
                         "01_Acausal_LV_Model.jl",
                         "02_Acausal_RLC_Model.jl",
                         "03_Acausal_Model_Parameter_Estimation.jl",
                         "04_Model_Calibration.jl",
                         "05_Surrogate_from_ODE.jl",
                         "06_Surrogate_from_FMU.jl",
                         "07_Surrogate_from_FMU_distributed.jl",
                         "08_Modeling_for_Control.jl",
                         "09_State_Estimation.jl"])

isdir(STATIC_PATH) || mkpath(STATIC_PATH)

for (dir, files) in pairs(scripts)
    for file in files
        Literate.markdown(joinpath(dir, file), joinpath(STATIC_PATH, dir))
    end
end
