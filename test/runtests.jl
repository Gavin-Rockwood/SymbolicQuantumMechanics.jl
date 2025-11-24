using Test
using SymQM

@testset "SymQM scaffold" begin
	@test isabstracttype(AbstractQuantumOperator)
	@test isabstracttype(QSym)
	# Check that QSym integrates with SymbolicUtils' variant hierarchy
	@test QSym <: SymbolicUtils.SymVariant
end
