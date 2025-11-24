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

function *(a::QMul, b::QMul)
    args_nc = vcat(a.args_nc, b.args_nc)
    arg_c = a.arg_c * b.arg_c
    return QMul(arg_c, args_nc)
end

Base.:/(a::QNumber, b::SNuN) = (1 / b) * a



function *(a::QAdd, b::SNuN)
    return QMul(b, [a])
end
function *(a::SNuN, b::QAdd)
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
