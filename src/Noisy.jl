module Noisy

export noise

using FFTW
using Random

function scale!(A, f, f₀, β)
    for i ∈ eachindex(A)
        A[i] = (f[i] < f₀ ? f₀ : f[i])^(-β/2)
    end
end

function σ(A, nf, nt)
    Σ = zero(eltype(A))
    for i ∈ eachindex(A)
        Σ += 1 < i < nf ? A[i]^2 : 0.0
    end
    Σ += (A[end] * (1 + (nt % 2)) / 2)^2
    2 * √Σ / nt
end

function noise(β, f₀, dims...)
    nt = dims[end]
    f = rfftfreq(nt)
    nf = size(f, 1)
    f₀ = 0 <= f₀ <= 0.5 ? max(f₀, 1/nt) : throw("ERROR: f₀ ∉ [0, 0.5].")

    G = Array{ComplexF64}(undef, dims[1:end-1]..., nf)
    A = Array{Float64}(undef, nf)
    scale!(A, f, f₀, β)

    x = randn(Float64, dims[1:end-1]..., nf)
    y = randn(Float64, dims[1:end-1]..., nf)
    
    # If the signal strength is even, the values
    # of this array at f = ± 0.5 are equal, which
    # means this value is real.
    if (nt % 2) != 0
        selectdim(
            y,
            ndims(y),
            lastindex(y, ndims(y)),
        ) .= 0.0
    end

    # Regardless of the length of the signal,
    # the DC component must be real.
    selectdim(
        y,
        ndims(y),
        firstindex(y, ndims(y)),
    ) .= 0.0

    
    for I in CartesianIndices(G)
        G[I] = A[Tuple(I)[end]] * (x[I] + (im * y[I]))
    end

    irfft(G, nt, ndims(G)) ./ σ(A, nf, nt)
end

"""
"""
noise

end
