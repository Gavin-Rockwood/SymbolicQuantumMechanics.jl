for T in (:SpinXOperator, :SpinYOperator, :SpinZOperator)
    @eval struct $T{TT} <: QSymbol
        name::String
        hilbertspace:: TT where TT<: Union{SpinHilbertSpace, CompositeHilbertSpace}
        index
        metadata
    end
    @eval function $T(name::String, hilbertspace:: TT, index, metadata) where TT<: Union{SpinHilbertSpace, CompositeHilbertSpace}
        return $T{TT}(name, hilbertspace, index, metadata)
    end
    @eval function $T(name::String, hilbertspace:: TT, index; metadata = NO_METADATA) where TT<: Union{SpinHilbertSpace, CompositeHilbertSpace}
        return $T{TT}(name, hilbertspace, index, metadata)
    end        
end