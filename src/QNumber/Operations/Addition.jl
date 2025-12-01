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
    args = _reduce_add([a, b])
    if length(args) == 1
        return args[1]
    else
        return QAdd(args)
    end
end

function +(a::QAdd, b::QNumber)
    args = _reduce_add(vcat(a.arguments, b))
    if length(args) == 1
        return args[1]
    else
        return QAdd(args)
    end
end
function +(b::QNumber, a::QAdd)
    args = _reduce_add(vcat(a.arguments, b))
    if length(args) == 1
        return args[1]
    else
        return QAdd(args)
    end
end
function +(a::QAdd, b::QAdd)
    args = _reduce_add(vcat(a.arguments, b.arguments))
    if length(args) == 1
        return args[1]
    else
        return QAdd(args)
    end
end