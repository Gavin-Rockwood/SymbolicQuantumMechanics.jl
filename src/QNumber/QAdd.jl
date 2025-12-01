"""
    QAdd <: QTerm

Represent an addition involving [`QNumber`](@ref) and other types.
"""
struct QAdd <: QTerm
    arguments
    metadata
    function QAdd(arguments, metadata)
        new(_reduce_add(arguments), metadata)
    end
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


function _flatten_add(args)
    new_args = []
    for i in 1:length(args)
        if args[i] isa QAdd
            push!(new_args, _flatten_add(args[i].arguments))
        elseif args[i] isa Number
            if isequal(args[i], 0)
                continue
            else
                push!(new_args, QMul(args[i], [Identity()]))
            end
        else
            push!(new_args, args[i])
        end
    end
    return new_args
end

function _reduce_add(args)
    args = _flatten_add(args)
    new_args_dict = Dict{Any, Any}()
    new_args = []
    for i in 1:length(args)
        arg = args[i] isa AbstractArray ? args[i] : [args[i]]
        if arg in keys(new_args_dict)
            new_args_dict[arg] += 1
        elseif arg[1] isa QMul
            if arg[1].args_nc in keys(new_args_dict)
                new_args_dict[arg[1].args_nc] += arg[1].arg_c
            else
                new_args_dict[arg[1].args_nc] = arg[1].arg_c
            end
        else
            new_args_dict[arg] = 1
        end
    end
    for key in keys(new_args_dict)
        if isequal(new_args_dict[key], 0)
            continue
        elseif isequal(new_args_dict[key], 1)
            push!(new_args, key[1])
            continue
        else
            push!(new_args, QMul(new_args_dict[key], key))
        end
    end
    return new_args
end
