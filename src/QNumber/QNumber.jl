export @qnumbers

include("QNumber_QSym_QTerm.jl")
export QNumber, QSym, QTerm
include("QPow.jl")
export QPow
include("QMul.jl")
export QMul
include("QAdd.jl")
export QAdd


include("Operations/Power.jl")
include("Operations/Multiplication.jl")
include("Operations/Addition.jl")

include("utils/Simplify.jl")
include("utils/Expand.jl")
export expand, full_expand
include("utils/Strings.jl")
include("utils/Show.jl")
export fshow


function source_metadata(source, name)
    Base.ImmutableDict{DataType,Any}(Symbolics.VariableSource, (source, name))
end

macro qnumbers(qs...)
    ex = Expr(:block)
    qnames = []
    for q in qs
        @assert q isa Expr && q.head == :(::)
        q_ = q.args[1]
        @assert q_ isa Symbol
        push!(qnames, q_)
        f = q.args[2]
        @assert f isa Expr && f.head == :call
        op = _make_operator(q_, f.args...)
        ex_ = Expr(:(=), esc(q_), op)
        push!(ex.args, ex_)
    end
    push!(ex.args, Expr(:tuple, map(esc, qnames)...))
    return ex
end

function _make_operator(name, T, h, args...)
    name_ = Expr(:quote, name)
    d = source_metadata(:qnumbers, name)
    return Expr(:call, T, esc(h), name_, args..., Expr(:kw, :metadata, Expr(:quote, d)))
end
function _make_operator(name, T, args...)
    name_ = Expr(:quote, name)
    d = source_metadata(:qnumbers, name)
    return Expr(:call, T, name_, args..., Expr(:kw, :metadata, Expr(:quote, d)))
end