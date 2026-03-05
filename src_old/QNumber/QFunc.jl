## Function of QSyms
"""
    QFunc <: QTerm

Represent a function of [`QSym`](@ref) types.

Fields:
======

* func: The function name.
* args: Arguments of the function.
"""
struct QFunc <: QTerm
    func::Symbol
    args::Vector{Any}
    metadata
    dag::Bool
    function QMul(func::Symbol, args::Vector{Any}, metadata, dag::Bool)
        return new(func, args, metadata, dag)
    end
end

QFunc(arg_c, args_nc; metadata=NO_METADATA, dag=false) = QFunc(arg_c, args_nc, metadata, dag)
Base.hash(q::QFunc, h::UInt) = hash(QFunc, hash(q.func, SymbolicUtils.hashvec(q.args, hash(q.dag, h))))

SymbolicUtils.operation(::QFunc) = (QFunc.func)
SymbolicUtils.arguments(a::QFunc) = QFunc.args
TermInterface.metadata(a::QFunc) = a.metadata

function Base.adjoint(q::QFunc)
    return QFunc(_conj(q.func), q.args; metadata=q.metadata, dag=!q.dag)
end

function Base.isequal(a::QFunc, b::QFunc)
    isequal(a.func, b.func) || return false
    length(a.args) == length(b.args) || return false
    for (arg_a, arg_b) in zip(a.args, b.args)
        isequal(arg_a, arg_b) || return false
    end
    return true
end