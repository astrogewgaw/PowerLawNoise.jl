module PowerLawNoise

using FFTW
using Random

zerolast!(A) = selectdim(A, ndims(A), lastindex(A, ndims(A))) .= 0.0
zerofirst!(A) = selectdim(A, ndims(A), firstindex(A, ndims(A))) .= 0.0

function σ(A, n₀, n₁)
    2 * √(
        sum([1 < i < n₁ ? A[i]^2 : 0.0 for i ∈ eachindex(A)]) + (A[end] * (1 + (n₀ % 2)) / 2)^2,
    ) / n₀
end

function scales!(A, ν, ν₀, β)
    for i ∈ LinearIndices(A)
        A[i] = (ν[i] < ν₀ ? ν₀ : ν[i])^(-β / 2)
    end
    A
end

function scales(ν, ν₀, β)
    A = similar(ν)
    scales!(A, ν, ν₀, β)
end

function noise(β, ν₀, dims...)
    n₀ = dims[end]
    ν = rfftfreq(n₀)
    ν₀ = 0 <= ν₀ <= 0.5 ? max(ν₀, n₀^-1) : throw("ν₀ ∉ [0, 0.5].")

    N = Array{ComplexF64}(undef, dims[1:end-1]..., size(ν, 1))

    X = randn(Float64, size(N)...)
    Y = randn(Float64, size(N)...)

    zerofirst!(Y)
    A = scales(ν, ν₀, β)
    (n₀ % 2) == 0 && zerolast!(Y)
    for i in CartesianIndices(N)
        N[i] = A[Tuple(i)[end]] * (X[i] + (im * Y[i]))
    end
    irfft(N, n₀, ndims(N)) ./ σ(A, size(A, 1), n₀)
end

end
