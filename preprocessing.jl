using CSV
using DataFrames
using Statistics
using Random

df = CSV.read("data/winequality-white.csv", DataFrame)

# We're going to classify it
# Low is <= 5
# Medium is 6
# High is >= 7
df.qualityC = ifelse.(df.quality .<= 5, :low, ifelse.(df.quality .==6, :medium, :high))
# select!(df, Not(:quality)) # keeping the quality column for regression perhaps

features = names(df, Not([:quality, :qualityC]))

# Noramlize features
for col in features
    μ = mean(df[:, col])
    σ = std(df[:, col])
    df[!, col] = (df[:, col] .- μ) ./ σ
end

# Split data
# 70% Train, 15% validation, 15% test

df_train = DataFrame()
df_val = DataFrame()
df_test = DataFrame()

for c in unique(df.qualityC)
    dfC = filter(x -> x.qualityC == c, df)
    dfC = dfC[shuffle(1:nrow(dfC)), :]

    train_size = ceil(Int, nrow(dfC) * 0.7)
    validate_size = ceil(Int, nrow(dfC) * 0.15)
    validate_ind_start = train_size + 1
    validate_ind_end = validate_ind_start + validate_size

    append!(df_train, dfC[1:train_size, :])
    append!(df_val, dfC[validate_ind_start:validate_ind_end, :])
    append!(df_test, dfC[(validate_ind_end+1):end, :])
end

CSV.write("train.csv", df_train)
CSV.write("val.csv", df_val)
CSV.write("test.csv", df_test)