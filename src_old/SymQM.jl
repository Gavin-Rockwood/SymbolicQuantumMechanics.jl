module SymQM
using Symbolics
using SymbolicUtils
using Revise
# Write your package code here.

include("QuantumOperator.jl")
include("BosonicOperator.jl")
include("PositionMomentum.jl")
include("FermionicOperator.jl")
export AbstractQuantumObject
export Scalar, FuncOp, fop
export BosonicOperator, BOp, dag, OpSum, normal_order, δ
export XOp, POp, normal_order_c
export FermionicOperator, FOp, FSum, normal_order_f
	export IdentityOperator, Identity
export QTerm, QSum
export use_apostrophe!, use_dagger!, set_conjugate_style!, get_conjugate_style

# Converters into QSum for cross-family commuting arithmetic
QSum(s::OpSum) = QSum([QTerm(t.coeff, AbstractQuantumObject[t.factors...]) for t in s.terms])
## SumC removed; canonical normal-ordering now returns QSum directly
QSum(s::FSum) = QSum([QTerm(t.coeff, AbstractQuantumObject[t.factors...]) for t in s.terms])

	# Backward-compatible alias for IdentityOperator
	const Identity = IdentityOperator

end
