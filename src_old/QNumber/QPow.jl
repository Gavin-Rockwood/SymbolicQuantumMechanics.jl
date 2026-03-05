struct QPow{T} <: QTerm
    x#::T where T <: QNumber
    y::T
    metadata
    function QPow{T}(x, y, metadata) where {T}
        if SymbolicUtils._iszero(y)
            return 1
        elseif SymbolicUtils._isone(y)
            return x
        else
            return new(x, y, metadata)
        end
    end
end

QPow(x, y::T; metadata=NO_METADATA) where {T} = QPow{T}(x, y, metadata)
Base.hash(q::QPow, h::UInt) = hash(QPow, hash(q.x, SymbolicUtils.hashvec(q.y, h)))

SymbolicUtils.operation(::QPow) = (^)
SymbolicUtils.arguments(a::QPow) = [a.x, a.y]
SymbolicUtils.metadata(a::QPow) = a.metadata

SymbolicUtils.maketerm(::Type{<:QPow}, ::typeof(^), args, metadata) = QPow(args[1], args[2]; metadata)

function Base.isequal(a::QPow, b::QPow)
    if !isequal(a.x, b.x)
        return false
    elseif !isequal(a.y, b.y)
        return false
    end
    return true
end