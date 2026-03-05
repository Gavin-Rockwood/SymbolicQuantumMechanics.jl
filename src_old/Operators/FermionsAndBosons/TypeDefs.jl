"""
    Destroy <: QSym

Bosonic operator on a [`FockSpace`](@ref) representing the quantum harmonic
oscillator annihilation operator.
"""
struct Boson <: QSym
    at
    name::Symbol
    metadata
    dag::Bool
    function Boson(at, name::Symbol, metadata, dag::Bool)
        new(at, name, metadata, dag)
    end
end

struct Fermion <: QSym
    at
    name::Symbol
    metadata
    dag::Bool
    function Fermion(at, name::Symbol, metadata, dag::Bool)
        new(at, name, metadata, dag)
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
    #@eval $(f)(at, name; metadata=NO_METADATA, dag::Bool=false) = $(f)(at, name, metadata, dag)
    @eval $(f)(name; metadata=NO_METADATA, dag::Bool=false) = $(f)(nothing, name, metadata, dag)

    @eval function (x::$f)(at)
        field_names = fieldnames(typeof(x))
        field_data = [getfield(x, field_name) for field_name in field_names]
        field_data[findfirst(==(:at), fieldnames($f))] = at
        return $f(field_data...)
    end

    @eval function (x::$f)(; kwargs...)
        field_names = fieldnames(typeof(x))
        field_data = [getfield(x, field_name) for field_name in field_names]

        for (key, value) in kwargs
            field_data[findfirst(==(key), fieldnames($f))] = value
        end
        return $f(field_data...)
    end
    @eval function Base.isless(a::$f, b::$f)
        if !isequal(a.dag, b.dag)
            return a.dag < b.dag
        elseif a.name != b.name
            return isless(a.name, b.name)
        else !isequal(a.at, b.at)
            # Handle symbolic comparison: use hash or string representation
            return hash(a.at) < hash(b.at)
        end
    end
end