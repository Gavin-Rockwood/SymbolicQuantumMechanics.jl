function simplify_coeff(q::SymbolicQuantumMechanics.QMul; kwargs...)
    # Simplify the commutative argument
    new_arg_c = simplify(q.arg_c; kwargs...)
    # Recursively simplify non-commutative arguments
    new_args_nc = map(arg -> simplify_coeff(arg; kwargs...), q.args_nc)
    return SymbolicQuantumMechanics.QMul(new_arg_c, new_args_nc; metadata=q.metadata)
end

function simplify_coeff(q::SymbolicQuantumMechanics.QAdd; kwargs...)
    new_args = map(arg -> simplify_coeff(arg; kwargs...), q.arguments)
    return SymbolicQuantumMechanics.QAdd(new_args; metadata=q.metadata)
end

function simplify_coeff(q::SymbolicQuantumMechanics.QPow; kwargs...)
    new_x = simplify_coeff(q.x; kwargs...)
    # Exponent is usually a number but good to be safe if it can be symbolic
    new_y = simplify_coeff(q.y; kwargs...) 
    return SymbolicQuantumMechanics.QPow(new_x, new_y; metadata=q.metadata)
end

# Fallback for other types (QSym, Number, Symbol, etc.)
simplify_coeff(x; kwargs...) = x
