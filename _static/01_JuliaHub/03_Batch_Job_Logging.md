# Running Better Batch Jobs on JuliaHub
Now that we know the basics, let's see what additional functionality JuliaHub provides to monitor and analyze batch jobs.

````julia
using ModelingToolkit, Plots, DifferentialEquations, JSON3
````

## Rich Logging
Use Julia's logging macros to gain better insight to job progress.
Log messages can be added throughout your code and executed interactively or in batch.

````julia
@warn "About to write log message."
x = 1
@info "Attach variables to the message." x a=42.0

@variables t x(t) y(t)
@parameters α β δ γ
D = Differential(t)
eqs = [D(x) ~ α * x - β * x * y
       D(y) ~ δ * x * y - γ * y];

@named model = ODESystem(eqs, t);
````

## Inputs
Users can choose to provide inputs values for any variable.
This enables running different simulations with zero code changes.
Additionally, specified inputs will appear in the Job Details for record keeping.
In the **Inputs** section of the JuliaHub extension:
- Click plus, `+`, to add an input key-value pair
- Enter the second argument of the `get` call as the key
- Enter the desired number as the value
Any input not provided will fall back to its default value.

````julia
input_tstop = parse(Float64, get(ENV, "input_tstop", "3600.0")) # get value of `input_tstop` or use default value 3600.0
input_x = parse(Float64, get(ENV, "input_x", "0.9")) # get value of `input_x` or use default value 0.9
input_y = parse(Float64, get(ENV, "input_y", "1.8")) # get value of `input_y` or use default value 1.8

prob = ODEProblem(model,
                  [x => input_x, y => input_y],
                  (0, input_tstop),
                  [α => 2 / 3, β => 4 / 3, γ => 1, δ => 1])
sol = solve(prob)
````

## Outputs
Batch jobs can have two types of outputs: JSON objects or files.

Each type of output can be easily accessed after a job is completed.
JSON objects can be viewed from the [Job List](https://juliahub.com/ui/Jobs) by clicking on a job's Details.
The JSON object will be displayed under the **Outputs** section in Details.
Preparing this output is a simple matter of assigning the `RESULTS` environment variable to the desired JSON object.
First, define a dictionary with the appropriate output data.

````julia
results = Dict(:return_code => sol.retcode, :x_final => first(sol[end]),
               :y_final => last(sol[end]))
````

Then, convert the Julia dictionary to a JSON object and assign it to `RESULTS`.

````julia
ENV["RESULTS"] = JSON3.write(results)
````

Job outputs can also be files.
Any job with output files will be denoted in the [Job List](https://juliahub.com/ui/Jobs) with a file icon.
Clicking on that job's Details will show a tar file in the **Output Files** section.
Preparing this output requires users to add logic to their code to save the output files
and assign the `RESULTS_FILE` environment variable to the filepath.
If you wish for the job output to be a single file, then use the path to that file.
If you wish for the job output to be multiple files, then use the path to the directory containing all outputs.

First, make the path where we will save our outputs.

````julia
results_path = joinpath(@__DIR__, "results")
mkpath(results_path)
````

Then, save results in the output path.

````julia
plot(sol)
savefig(joinpath(results_path, "solution.png"))
````

Finally, assign `RESULTS_FILE` to the path of the directory containing the output.

````julia
ENV["RESULTS_FILE"] = results_path
````

## FAQ
Batch jobs have a limit on the size of **Bundle directory**.
Create a `.juliabundleignore` at the root of the bundle and specify the paths which are not necessary for successful execution.

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

