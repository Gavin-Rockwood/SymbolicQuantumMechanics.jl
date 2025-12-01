function *(a::QSym, b::QSym)
    args = [a, b]
    #sort!(args; by=acts_at)
    QMul(1, args)
end

function *(a::QSym, b::SNuN)
    SymbolicUtils._iszero(b) && return b
    SymbolicUtils._isone(b) && return a
    return QMul(b, [a])
end
*(b::SNuN, a::QNumber) = a * b

function *(a::QMul, b::SNuN)
    SymbolicUtils._iszero(b) && return b
    SymbolicUtils._isone(b) && return a
    arg_c = a.arg_c * b
    return QMul(arg_c, a.args_nc)
end
function *(b::SNuN, a::QMul)
    return a * b
end

function *(a::QSym, b::QMul)
    args_nc = vcat(a, b.args_nc)
    return QMul(b.arg_c, args_nc)
end
function *(a::QMul, b::QSym)
    args_nc = vcat(a.args_nc, b)
    return QMul(a.arg_c, args_nc)
end

function *(a::QPow, b::T) where T<:QNumber
    if a.x == b
        new_exponent = a.y + 1
        return QPow(a.x, new_exponent; metadata=a.metadata)
    else
        args_nc = [a, b]
        return QMul(1, args_nc)
    end
end
function *(a::T, b::QPow) where T<:QNumber
    if a == b.x
        new_exponent = b.y + 1
        return QPow(b.x, new_exponent; metadata=b.metadata)
    else
        args_nc = [a, b]
        return QMul(1, args_nc)
    end
end
function *(a::T, b::T) where T<:QPow
    if a.x == b.x
        new_exponent = a.y + b.y
        return QPow(a.x, new_exponent; metadata=a.metadata)
    else
        args_nc = [a, b]
        return QMul(1, args_nc)
    end
end


function *(a::QMul, b::QMul)
    arg_c = a.arg_c * b.arg_c
    if isequal(a.args_nc, b.args_nc)
        x = QMul(1, a.args_nc)
        y = 2
        return arg_c * QPow(x, y)
    else
        args_nc = vcat(a.args_nc, b.args_nc)
        return QMul(arg_c, args_nc)
    end
end

Base.:/(a::QNumber, b::SNuN) = (1 / b) * a



function *(a::QAdd, b::SNuN)
    return QMul(b, [a])
end
function *(a::SNuN, b::QAdd)
    return QMul(a, [b])
end
function *(a::QPow, b::SNuN)
    return QMul(b, [a])
end
function *(a::SNuN, b::QPow)
    return QMul(a, [b])
end
function *(a::T, b::QAdd) where T<:QNumber
    return QMul(1, [a, b])
end
function *(a::QAdd, b::T) where T<:QNumber
    return QMul(1, [a, b])
end
function *(a::QAdd, b::QAdd)
    return QMul(1, [a, b])
end
