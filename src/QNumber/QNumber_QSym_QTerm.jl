"""
    QNumber

Abstract type representing any expression involving operators.
"""
abstract type QNumber end

"""
    QSym <: QNumber

Abstract type representing fundamental operator types.
"""
abstract type QSym <: QNumber end

# Generic hash fallback for interface -- this will be slow
function Base.hash(op::T, h::UInt) where {T<:QSym}
    n = fieldcount(T)
    if n == 3
        # These three fields need to be defined for any QSym
        return hash(T, hash(op.hilbert, hash(op.name, hash(op.at, h))))
    else
        # If there are more we'll need to iterate through
        h_ = copy(h)
        for k in n:-1:4
            if fieldname(typeof(op), k) !== :metadata
                h_ = hash(getfield(op, k), h_)
            end
        end
        return hash(T, hash(op.hilbert, hash(op.name, hash(op.at, h_))))
    end
end

"""
    QTerm <: QNumber

Abstract type representing noncommutative expressions.
"""
abstract type QTerm <: QNumber end

Base.isless(a::QSym, b::QSym) = a.name < b.name

## Interface for SymbolicUtils

TermInterface.head(::QNumber) = :call
SymbolicUtils.iscall(::QSym) = false
SymbolicUtils.iscall(::QTerm) = true
SymbolicUtils.iscall(::Type{T}) where {T<:QTerm} = true
TermInterface.metadata(x::QNumber) = x.metadata

# Symbolic type promotion
SymbolicUtils.promote_symtype(f, Ts::Type{<:QNumber}...) = promote_type(Ts...)
SymbolicUtils.promote_symtype(f, T::Type{<:QNumber}, Ts...) = T
SymbolicUtils.promote_symtype(f, T::Type{<:QNumber}, S::Type{<:Number}) = T
SymbolicUtils.promote_symtype(f, T::Type{<:Number}, S::Type{<:QNumber}) = S
function SymbolicUtils.promote_symtype(f, T::Type{<:QNumber}, S::Type{<:QNumber})
    promote_type(T, S)
end

SymbolicUtils.symtype(x::T) where {T<:QNumber} = T