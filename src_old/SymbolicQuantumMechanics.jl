module SymbolicQuantumMechanics

using TermInterface
using Symbolics
using SymbolicUtils

using Latexify
using LaTeXStrings

using Reexport

using .SymbolicUtils: NO_METADATA
import .Symbolics: simplify, expand
using .SymbolicUtils.Rewriters



import Base: *, +, -, ^
const SNuN = Union{<:SymbolicUtils.Symbolic{<:Number},<:Number}

QuantumSimplificationRules = []

include("QNumber/QNumber.jl")
include("Operators/Operators.jl")


end # module SymQM
