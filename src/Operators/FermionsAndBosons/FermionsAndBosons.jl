"""
    Destroy <: QSym

Bosonic operator on a [`FockSpace`](@ref) representing the quantum harmonic
oscillator annihilation operator.
"""
struct Boson{L,M} <: QSym
    at::L
    name::Symbol
    metadata::M
    dag::Bool
    function Boson(at::L, name::Symbol, metadata::M, dag::Bool) where {L,M}
        new{L,M}(at, name, metadata, dag)
    end
end

struct Fermion{L,M} <: QSym
    at::L
    name::Symbol
    metadata::M
    dag::Bool
    function Fermion(at::L, name::Symbol, metadata::M, dag::Bool) where {L,M}
        new{L,M}(at, name, metadata, dag)
    end
end

for T in (:Boson, :Fermion)
    @eval Base.isequal(a::$T, b::$T) =
        isequal(a.at, b.at) && isequal(a.metadata, b.metadata) && isequal(a.dag, b.dag) && isequal(a.name, b.name)
    @eval Base.adjoint(a::$T) = $(T)(
        a.at,
        a.name,
        metadata=a.metadata,
        dag=!a.dag
    )
end


for f in [:Boson, :Fermion]
    @eval $(f)(at, name; metadata=NO_METADATA, dag::Bool=false) = $(f)(at, name, metadata, dag)
    @eval $(f)(at, name; metadata=NO_METADATA, dag::Bool=false) = $(f)(at, name, metadata, dag)
    @eval $(f)(name; metadata=NO_METADATA, dag::Bool=false) = $(f)(nothing, name, metadata, dag)
end