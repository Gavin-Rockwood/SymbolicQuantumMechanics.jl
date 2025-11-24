## Multiplication
"""
    QMul <: QTerm

Represent a multiplication involving [`QSym`](@ref) types.

Fields:
======

* arg_c: The commutative prefactor.
* args_nc: A vector containing all [`QSym`](@ref) types.
"""
struct QMul{M} <: QTerm
    arg_c
    args_nc::Vector{Any}
    metadata::M
    function QMul{M}(arg_c, args_nc, metadata) where {M}
        if SymbolicUtils._isone(arg_c) && length(args_nc) == 1
            return args_nc[1]
        elseif (0 in args_nc) || isequal(arg_c, 0)
            return 0
        else
            return new(arg_c, args_nc, metadata)
        end
    end
end
QMul(arg_c, args_nc; metadata::M=NO_METADATA) where {M} = QMul{M}(arg_c, args_nc, metadata)
Base.hash(q::QMul, h::UInt) = hash(QMul, hash(q.arg_c, SymbolicUtils.hashvec(q.args_nc, h)))

SymbolicUtils.operation(::QMul) = (*)
SymbolicUtils.arguments(a::QMul) = vcat(a.arg_c, a.args_nc)

function TermInterface.maketerm(::Type{<:QMul}, ::typeof(*), args, metadata)
    args_c = filter(x -> !(x isa QNumber), args)
    args_nc = filter(x -> x isa QNumber, args)
    arg_c = *(args_c...)
    isempty(args_nc) && return arg_c
    return QMul(arg_c, args_nc; metadata)
end

TermInterface.metadata(a::QMul) = a.metadata

function Base.adjoint(q::QMul)
    args_nc = map(_adjoint, q.args_nc)
    reverse!(args_nc)
    #sort!(args_nc; by=acts_at)
    return QMul(_conj(q.arg_c), args_nc; q.metadata)
end

function Base.isequal(a::QMul, b::QMul)
    isequal(a.arg_c, b.arg_c) || return false
    length(a.args_nc) == length(b.args_nc) || return false
    for (arg_a, arg_b) in zip(a.args_nc, b.args_nc)
        isequal(arg_a, arg_b) || return false
    end
    return true
end
