-(a::QNumber) = -1 * a
-(a, b::QNumber) = a + (-b)
-(a::QNumber, b) = a + (-b)
-(a::QNumber, b::QNumber) = a + (-b)

function +(a::QNumber, b::SNuN)
    SymbolicUtils._iszero(b) && return a
    return QAdd([a, b])
end
+(a::SNuN, b::QNumber) = +(b, a)
function +(a::QAdd, b::SNuN)
    SymbolicUtils._iszero(b) && return a
    args = vcat(a.arguments, b)
    return QAdd(args)
end

function +(a::QNumber, b::QNumber)
    args = [a, b]
    return QAdd(args)
end

function +(a::QAdd, b::QNumber)
    args = vcat(a.arguments, b)
    return QAdd(args)
end
function +(b::QNumber, a::QAdd)
    args = vcat(a.arguments, b)
    return QAdd(args)
end
function +(a::QAdd, b::QAdd)
    args = vcat(a.arguments, b.arguments)
    return QAdd(args)
end

function flatten_adds!(args)
    i = 1
    while i <= length(args)
        if args[i] isa QAdd
            append!(args, args[i].arguments)
            deleteat!(args, i)
        elseif SymbolicUtils._iszero(args[i]) || isequal(args[i], 0)
            deleteat!(args, i)
        else
            i += 1
        end
    end
    return args
end
