module SymbolicQuantumMechanics

using TermInterface
using Symbolics
using SymbolicUtils

using Latexify
using LaTeXStrings

using Reexport

using .SymbolicUtils: NO_METADATA



import Base: *, +, -, ^
const SNuN = Union{<:SymbolicUtils.Symbolic{<:Number},<:Number}


include("QNumber/QNumber.jl")
include("Operators/Operators.jl")


end # module SymQM
