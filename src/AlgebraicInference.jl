module AlgebraicInference


# Systems
export CanonicalForm, DenseCanonicalForm, DenseGaussianSystem, GaussianSystem
export ⊗, cov, invcov, normal, kernel, mean, oapply, var


# Inference Problems
export InferenceProblem
export init, reduce_to_context


# Inference Solvers
export InferenceSolver
export solve, solve!


# Elimination
export ChordalGraph, EliminationAlgorithm, EliminationTree, AMDJL_AMD, CuthillMcKeeJL_RCM,
       JoinTree, MaximalSupernode, MetisJL_ND, MaxCardinality, MinDegree, MinFill, Node,
       Order, OrderedGraph, SupernodeType


# Architectures
export ArchitectureType, LauritzenSpiegelhalter, ShenoyShafer


using AbstractTrees
using Catlab, Catlab.Programs
using CommonSolve
using Distributions
using FillArrays
using LinearAlgebra
using LinearSolve
using Random
using Statistics


using AbstractTrees: parent
using Base: OneTo
using Distributions: rand!
using FillArrays: SquareEye, ZerosMatrix, ZerosVector
using LinearAlgebra: checksquare
using LinearSolve: SciMLLinearSolveAlgorithm
using Random: default_rng

import AMD
import BayesNets
import CuthillMcKee
import Graphs
import Metis


include("./kkt.jl")
include("./systems.jl")
include("./conditionals.jl")
include("./samplers.jl")
include("./factors.jl")
include("./cpds.jl")
include("./labels.jl")
include("./models.jl")
include("./elimination.jl")
include("./architectures.jl")
include("./problems.jl")
include("./solvers.jl")
include("./utils.jl")


end
