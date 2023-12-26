using Test
using FFTW
using CurveFit
using PowerLawNoise

@testset "PowerLawNoise.jl" begin
    β = 2.0
    ts = PowerLawNoise.noise(β, 0.0, 1000)
    ν = rfftfreq(size(ts, 1))
    P = abs.(rfft(ts)) .^ 2
    _, b = linear_fit(log10.(ν[2:end]), log10.(P[2:end]))
    @test -b ≈ β atol = 0.1
end
