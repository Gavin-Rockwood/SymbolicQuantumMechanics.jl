struct PositionOperator{T} <: QSymbol
    name::String
    hilbertspace:: T where T<: Union{SingleParticleHilbertSpace, CompositeHilbertSpace}
    index
    metadata
end
function PositionOperator(name::String, hilbertspace:: T, index, metadata) where T<: Union{SingleParticleHilbertSpace, CompositeHilbertSpace}
    return PositionOperator{T}(name, hilbertspace, index, metadata)
end


struct MomentumOperator{T} <: QSymbol
    name::String
    hilbertspace:: T where T<: Union{SingleParticleHilbertSpace, CompositeHilbertSpace}
    index
    metadata
end
function MomentumOperator(name::String, hilbertspace:: T, index, metadata) where T<: Union{SingleParticleHilbertSpace, CompositeHilbertSpace}
    return MomentumOperator{T}(name, hilbertspace, index, metadata)
end


struct LadderOperator{T} <: QSymbol
    name::String
    hilbertspace:: T where T<: Union{SingleParticleHilbertSpace, CompositeHilbertSpace}
    index
    metadata
    dagger::Bool
end
function LadderOperator(name::String, hilbertspace:: T, index, metadata, dagger) where T<: Union{SingleParticleHilbertSpace, CompositeHilbertSpace}
    return LadderOperator{T}(name, hilbertspace, index, metadata, dagger)
end
function LadderOperator(name::String, hilbertspace:: T, index, metadata; dagger = false) where T<: Union{SingleParticleHilbertSpace, CompositeHilbertSpace}
    return LadderOperator{T}(name, hilbertspace, index, metadata, dagger)
end


for T in (:PositionOperator, :MomentumOperator, :LadderOperator)
    @eval function $T(x, hilbertspace::SingleParticleHilbertSpace; metadata=NO_METADATA)
        $T(string(x), hilbertspace, 0, metadata)
    end
    @eval function $T(x, hilbertspace::SingleParticleHilbertSpace; metadata=NO_METADATA)
        return $T(string(x), hilbertspace, 0, metadata)
    end
    @eval function $T(x, hilbertspace::CompositeHilbertSpace, idx; metadata=NO_METADATA)
        return $T(string(x), hilbertspace, idx, metadata)
    end
        
end