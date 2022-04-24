module Noisy

export noise

using FFTW
using Random

zerofirst!(A) = selectdim(A, ndims(A), lastindex(A, ndims(A))) .= 0.0
zerolast!(A) = selectdim(A, ndims(A), firstindex(A, ndims(A))) .= 0.0

function scale!(A, f, f₀, β)
    for I ∈ LinearIndices(A)
        A[I] = (f[I] < f₀ ? f₀ : f[I])^(-β/2)
    end
end

function σ(A, nf, nt)
    Σ = zero(eltype(A))
    for I ∈ LinearIndices(A)
        Σ += 1 < I < nf ? A[I]^2 : 0.0
    end
    Σ += (A[end] * (1 + (nt % 2)) / 2)^2
    2 * √Σ / nt
end

function noise!(X, A, f, f₀, nt, β)
    x = randn(Float64, size(X)...)
    y = randn(Float64, size(X)...)
    (nt % 2) == 0 && zerolast!(y)
    zerofirst!(y)
    for I in CartesianIndices(X)
        X[I] = A[Tuple(I)[end]] * (x[I] + (im * y[I]))
    end
    irfft(X, nt, ndims(X)) ./ σ(A, size(A, 1), nt)
end

function noise(β, f₀, dims...)
    nt = dims[end]
    f = rfftfreq(nt)
    f₀ = 0 <= f₀ <= 0.5 ? max(f₀, 1/nt) : throw("ERROR: f₀ ∉ [0, 0.5].")
    X = Array{ComplexF64}(undef, dims[1:end-1]..., size(f, 1))
    A = similar(f)
    scale!(A, f, f₀, β)
    noise!(X, A, f, f₀, nt, β)
end

"""
"""
noise

end
