using MLJ, Plots, Statistics, LinearAlgebra, DataFrames
import CSV
using JuMP, Ipopt

const filtered_data = false

const df_train_all = CSV.read("train.csv", DataFrame)
const df_train_filtered = CSV.read("train_f.csv", DataFrame)
const df_train = filtered_data ? df_train_filtered : df_train_all
const df_val = CSV.read("val.csv", DataFrame)
const df_test = CSV.read("test.csv", DataFrame)

const features = names(df_train, Not([:quality, :qualityC]))

const df_train_2 = filter(x -> x.qualityC != "medium", df_train)
const df_val_2 = filter(x -> x.qualityC != "medium", df_val)
const df_test_2 = filter(x -> x.qualityC != "medium", df_test)

const X_train = Matrix(df_train_2[:, features])
const X_val = Matrix(df_val_2[:, features])
const X_test = Matrix(df_test_2[:, features])
const t_train = ifelse.(df_train_2.qualityC .== "low", -1, 1)
const t_val = ifelse.(df_val_2.qualityC .== "low", -1, 1)
const t_test = ifelse.(df_test_2.qualityC .== "low", -1, 1)

function train_soft_svc(X, t, C)
    N, M = size(X_train)

    model = JuMP.Model(Ipopt.Optimizer)
    set_optimizer_attribute(model, "print_level", 0)
    Q = zeros(N, N)
    for i in 1:N
        for j in 1:N
            Q[i,j] = t[i] * t[j] * dot(X[i,:], X[j,:])
        end
    end
    @variable(model, α[1:N] >= 0)

    p = ones(N) * -1
    @objective(model, Min, 0.5 * dot(α, Q * α) + dot(p, α))

    # p = ones(N)
    # @objective(model, Min, dot(p, α) - 0.5 * dot(α, Q * α))

    @constraint(model, sum(α[i] * t[i] for i in 1:N) == 0)

    C = 1.0
    for i in 1:N
        @constraint(model, α[i] <= C)
    end

    optimize!(model)

    α_opt = value.(α)
    ϵ = 1e-5
    num_support_vecs = count(x -> abs(x) > ϵ, α_opt)

    # Compute b
    K = zeros(N,N)
    for i in 1:N
        for j in 1:N
            K[i,j] = dot(X[i,:], X[j,:])
        end
    end

    prod = t .- (K .* α_opt .* t)
    b = 


    println(num_support_vecs)
    return α_opt
end

C = 1.0
α_opt = train_soft_svc(X_train, t_train, C)
