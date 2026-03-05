"""
    QExpression

Abstract type representing any expression involving operators.
"""
abstract type QExpression end

"""
    QSymbol <: QExpression
Abstract type representing fundamental operator types.
"""
abstract type QSymbol <: QExpression end


function Base.hash(x::T, h::UInt) where {T<:QSymbol}
    n = fieldcount(T)
    if n == 3
        # These three fields need to be defined for any QSym
        return hash(T, hash(x.name, hash(x.hilbertspace, h)))
    else
        # If there are more we'll need to iterate through
        h_ = copy(h)
        for k in n:-1:4
            if fieldname(typeof(x), k) !== :metadata
                h_ = hash(getfield(x, k), h_)
            end
        end
        return hash(T, hash(x.name, hash(x.hilbertspace, h_)))
    end
end


"""
    QTerm <: QExpression
Abstract type representing combinations of QSymbols.
"""
abstract type QTerm <: QExpression end


Base.isless(a::QSymbol, b::QSymbol) = Base.hash(a) < Base.hash(b)

## Interface for SymbolicUtils
TermInterface.head(::QExpression) = :call
SymbolicUtils.iscall(::QSymbol) = false
SymbolicUtils.iscall(::Type{T}) where {T<:QSymbol} = false
SymbolicUtils.iscall(::QTerm) = true
SymbolicUtils.iscall(::Type{T}) where {T<:QTerm} = true
TermInterface.metadata(x::QExpression) = x.metadata


# Symbolic type promotion
SymbolicUtils.promote_symtype(f, Ts::Type{<:QExpression}...) = promote_type(Ts...)
SymbolicUtils.promote_symtype(f, T::Type{<:QExpression}, Ts...) = T
SymbolicUtils.promote_symtype(f, T::Type{<:QExpression}, S::Type{<:Number}) = T
SymbolicUtils.promote_symtype(f, T::Type{<:Number}, S::Type{<:QExpression}) = S
function SymbolicUtils.promote_symtype(f, T::Type{<:QExpression}, S::Type{<:QExpression})
    promote_type(T, S)
end

SymbolicUtils.symtype(x::T) where {T<:QExpression} = T

get_hilbertspace(x::QExpression) = x.hilbertspace



struct Identity <: QSymbol
    name::String
    hilbertspace::AbstractHilbertSpace
    metadata
end
Identity(; metadata=NO_METADATA) = Identity("Identity", TotalHilbertSpace(); metadata)


struct TEST_SYMBOL <: QSymbol
    name::String
    hilbertspace::AbstractHilbertSpace
    metadata
end
TEST_SYMBOL(name::String, hilbertspace::AbstractHilbertSpace; metadata=NO_METADATA) = TEST_SYMBOL(name, hilbertspace, metadata)