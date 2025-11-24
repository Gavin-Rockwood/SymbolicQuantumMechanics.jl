function SymbolicUtils.simplify(x::QNumber; kwargs...)
    avg = average(x)
    avg_ = SymbolicUtils.simplify(avg; kwargs...)
    return undo_average(avg_)
end