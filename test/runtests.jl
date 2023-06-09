using AlgebraicInference
using Catlab, Catlab.Programs, Catlab.Theories
using LinearAlgebra
using Test

# Example 9
# https://www.kalmanfilter.net/multiExamples.html
@testset "Kalman Filter" begin
    F =  [
        1   1   1/2 0   0   0
        0   1   1   0   0   0
        0   0   1   0   0   0
        0   0   0   1   1   1/2
        0   0   0   0   1   1
        0   0   0   0   0   1
    ]

    Q =  [
        1/4 1/2 1/2 0   0   0
        1/2 1   1   0   0   0
        1/2 1   1   0   0   0
        0   0   0   1/4 1/2 1/2
        0   0   0   1/2 1   1
        0   0   0   1/2 1   1
    ] * 1/25

    H =  [
        1   0   0   0   0   0
        0   0   0   1   0   0
    ]

    R =  [
        9   0
        0   9
    ]

    P₀ = [
        500 0   0   0   0   0
        0   500 0   0   0   0
        0   0   500 0   0   0
        0   0   0   500 0   0
        0   0   0   0   500 0
        0   0   0   0   0   500
    ]

    z₁ = [
       -393.66
        300.40
        ]

    z₂ = [
       -375.93
        301.78
    ]

    true_cov = [
        8.92    11.33   5.13    0       0       0
        11.33   61.1    75.4    0       0       0
        5.13    75.4    126.5   0       0       0
        0       0       0       8.92    11.33   5.13
        0       0       0       11.33   61.1    75.4
        0       0       0       5.13    75.4    126.5]

    true_mean = [
       -378.9
        53.8
        94.5
        303.9
       -22.3
       -63.6
    ]

    wd = @relation (x21, x22, x23, x24, x25, x26) begin
        initial_state(x01, x02, x03, x04, x05, x06)
        predict(x01, x02, x03, x04, x05, x06, x11, x12, x13, x14, x15, x16)
        predict(x11, x12, x13, x14, x15, x16, x21, x22, x23, x24, x25, x26)
        measure(x11, x12, x13, x14, x15, x16, z11, z12)
        measure(x21, x22, x23, x24, x25, x26, z21, z22)
        observe₁(z11, z12)
        observe₂(z21, z22)
    end

    box_map = Dict(
        :initial_state => normal(P₀),
        :predict => kernel(Q, F),
        :measure => kernel(R, H),
        :observe₁ => normal(z₁),
        :observe₂ => normal(z₂))

    Σ = oapply(wd, box_map)
    @test isapprox(true_cov, cov(Σ); atol=0.1)
    @test isapprox(true_mean, mean(Σ); atol=0.1)

    prob = InferenceProblem(wd, box_map)
    query = prob.query
    @test query == [:x21, :x22, :x23, :x24, :x25, :x26]

    jt = init(prob, MinFill())
    @test_throws ErrorException("Query not covered by join tree.") solve(jt, [:x31])
    @test_throws ErrorException("Query not covered by join tree.") solve!(jt, [:x31])

    ϕ = solve(jt)
    M = [i == j for i in query, j in ϕ.labels]
    @test length(ϕ) == length(query)
    @test domain(ϕ) == query
    @test isapprox(true_cov, M * cov(ϕ.box) * M'; atol=0.1)
    @test isapprox(true_mean, M * mean(ϕ.box); atol=0.1)

    ϕ = solve!(jt)
    M = [i == j for i in query, j in ϕ.labels]
    @test length(ϕ) == length(query)
    @test domain(ϕ) == query
    @test isapprox(true_cov, M * cov(ϕ.box) * M'; atol=0.1)
    @test isapprox(true_mean, M * mean(ϕ.box); atol=0.1)

    prob.query = []
    jt = init(prob, MinWidth())
    ϕ = solve(jt, query)
    M = [i == j for i in query, j in ϕ.labels]
    @test length(ϕ) == length(query)
    @test domain(ϕ) == query
    @test isapprox(true_cov, M * cov(ϕ.box) * M'; atol=0.1)
    @test isapprox(true_mean, M * mean(ϕ.box); atol=0.1)

    ϕ = solve!(jt, query)
    M = [i == j for i in query, j in ϕ.labels]
    @test length(ϕ) == length(query)
    @test domain(ϕ) == query
    @test isapprox(true_cov, M * cov(ϕ.box) * M'; atol=0.1)
    @test isapprox(true_mean, M * mean(ϕ.box); atol=0.1)
end

@testset "Identity Valuation" begin
    ϕ = LabeledBox([:x, :y], normal([1 0; 0 1]))
    e = IdentityValuation{Symbol}()

    @test isempty(domain(e))
    @test eltype(domain(e)) == Symbol
    @test combine(e, e) === e
    @test combine(ϕ, e) === ϕ
    @test combine(e, ϕ) === ϕ
    @test project(e, []) === e
end
