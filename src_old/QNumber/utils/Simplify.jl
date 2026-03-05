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


"""
    simplify_quantum(expr; rules=[])

General simplification wrapper that:
1. Simplifies scalar coefficients using `simplify_coeff`.
2. Applies provided `rules` to the expression using `Fixpoint(Postwalk(Chain(rules)))`.
3. Re-simplifies coefficients.
"""
function simplify_quantum(expr; rules=QuantumSimplificationRules, max_iterations=10, coeff_kwargs...)
    # 1. Simplify coefficients
    expr = simplify_coeff(expr; coeff_kwargs...)
    i = 1
    while i <= max_iterations
        new_expr = expr
        if !isempty(rules)
            # 2. Apply rules
            rw = Fixpoint(Postwalk(Chain(rules)))
            new_expr = rw(new_expr)
        end

        # 3. Simplify coefficients again (in case rules created unsimplified scalars)
        new_expr = simplify_coeff(new_expr; coeff_kwargs...)
        if expr == new_expr
            break
        end
        expr = new_expr
        i += 1
    end

    return expr
end