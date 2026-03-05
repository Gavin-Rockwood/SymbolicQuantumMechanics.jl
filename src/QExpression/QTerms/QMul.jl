"""
QMul <: QTerm
    Represent a multiplication of [`QExpression`](@ref) types.
"""
struct QMul <: QTerm
    coeff
    arguments::Vector{Any}
    hilbertspace::AbstractHilbertSpace
    metadata
    function QMul(coeff, arguments, hilbertspace, metadata)
        if SymbolicUtils._isone(coeff) && length(arguments) == 1
            return arguments[1]
        elseif (0 in arguments) || isequal(coeff, 0)
            return 0
        else
            arguments = _reduce_mul(arguments)
            if length(arguments) == 1 && SymbolicUtils._isone(coeff)
                return arguments[1]
            end
            return new(coeff, arguments, hilbertspace, metadata)
        end
    end
end

QMul(coeff, arguments, hilbertspace; metadata=NO_METADATA) = QMul(coeff, arguments, hilbertspace, metadata)
QMul(coeff, arguments; metadata=NO_METADATA) = QMul(coeff, arguments, TensorProductHilbertSpace(map(get_hilbertspace, arguments)); metadata)
QMul(arguments; metadata=NO_METADATA) = QMul(1, arguments, TensorProductHilbertSpace(map(get_hilbertspace, arguments)); metadata)


Base.hash(q::QMul, h::UInt) = hash(QMul, hash(q.coeff, SymbolicUtils.hashvec(q.arguments, hash(q.hilbertspace, h))))
SymbolicUtils.operation(::QMul) = (*)
SymbolicUtils.arguments(a::QMul) = vcat(a.coeff, a.arguments)

function TermInterface.maketerm(::Type{<:QMul}, ::typeof(*), args, metadata)
    coeffs = filter(x -> !(x isa QExpression), args)
    arguments = filter(x -> x isa QExpression, args)
    coeff = *(coeffs...)
    isempty(arguments) && return coeff
    return QMul(coeff, arguments, TensorProductHilbertSpace(sort(map(get_hilbertspace, arguments))); metadata)
end

TermInterface.metadata(a::QMul) = a.metadata

function Base.adjoint(q::QMul)
    arguments = map(adjoint, q.arguments)
    reverse!(arguments)
    #sort!(arguments; by=acts_at)
    return QMul(adjoint(q.coeff), arguments, QMul.hilbertspace; metadata = q.metadata)
end

function Base.isequal(a::QMul, b::QMul)
    isequal(a.coeff, b.coeff) || return false
    length(a.arguments) == length(b.arguments) || return false
    for (arg_a, arg_b) in zip(a.arguments, b.arguments)
        isequal(arg_a, arg_b) || return false
    end
    return true
end

function _reduce_mul(args)
    new_args = Any[args[1]]
    for i in 2:length(args)
        if !(args[i] isa Identity)
            if _can_combine(new_args[end], args[i])
                combined = _combine(new_args[end], args[i])
                new_args[end] = combined
            else
                push!(new_args, args[i])
            end
        end
    end
    return new_args
end
