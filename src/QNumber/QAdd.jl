"""
    QAdd <: QTerm

Represent an addition involving [`QNumber`](@ref) and other types.
"""
struct QAdd <: QTerm
    arguments::Vector{Any}
    metadata
end

QAdd(x; metadata=NO_METADATA) = QAdd(x, metadata)

Base.hash(q::T, h::UInt) where {T<:QAdd} = hash(T, SymbolicUtils.hashvec(q.arguments, h))
function Base.isequal(a::QAdd, b::QAdd)
    length(a.arguments) == length(b.arguments) || return false
    for (arg_a, arg_b) in zip(a.arguments, b.arguments)
        isequal(arg_a, arg_b) || return false
    end
    return true
end

SymbolicUtils.operation(::QAdd) = (+)
SymbolicUtils.arguments(a::QAdd) = a.arguments
TermInterface.maketerm(::Type{<:QAdd}, ::typeof(+), args, metadata) = QAdd(args)
TermInterface.metadata(::QAdd) = NO_METADATA

Base.adjoint(q::QAdd) = QAdd(map(_adjoint, q.arguments))