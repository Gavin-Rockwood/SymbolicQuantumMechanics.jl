struct QPow{M,T} <: QTerm
    x#::T where T <: QNumber
    y::T
    metadata::M
    function QPow{M,T}(x, y, metadata) where {M,T}
        if SymbolicUtils._iszero(y)
            return 1
        elseif SymbolicUtils._isone(y)
            return x
        else
            return new(x, y, metadata)
        end
    end
end

QPow(x, y::T; metadata::M=NO_METADATA) where {M,T} = QPow{M,T}(x, y, metadata)
Base.hash(q::QPow, h::UInt) = hash(QPow, hash(q.x, SymbolicUtils.hashvec(q.y, h)))

SymbolicUtils.operation(::QPow) = (^)
SymbolicUtils.arguments(a::QPow) = (a.x)