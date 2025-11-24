abstract type AbstractQuantumObject end
abstract type AbstractQSum end

# General utilities and generic function-of-operator support

# Scalar coefficients allowed in operator sums
const Scalar = Union{Number, Symbolics.Num}

# Generic function-of-operator wrapper: f(op1, op2, ...)
struct FuncOp{F} <: AbstractQuantumObject
    fname::F
    args::Vector{AbstractQuantumObject}
end

# IdentityOperator: wrapper for symbolic variables or numbers that should act like
# an operator which commutes with everything. Use IdentityOperator(x) to wrap
# Symbolics.Num or Number when mixing with Quantum objects.
struct IdentityOperator <: AbstractQuantumObject
    var::Any
end

family_rank(::IdentityOperator) = 50
Base.show(io::IO, id::IdentityOperator) = print(io, id.var)

# Generic mixed-family sum/product where different operator families commute
struct QTerm
    coeff::Scalar
    factors::Vector{AbstractQuantumObject}
end
struct QSum <: AbstractQSum
    terms::Vector{QTerm}
end

QSum() = QSum(QTerm[])
QSum(c::Scalar) = QSum([QTerm(c, AbstractQuantumObject[])])
QSum(op::AbstractQuantumObject) = QSum([QTerm(one(Int), [op])])

# Family rank for commuting across families; specific types extend these
family_rank(::AbstractQuantumObject) = 100
family_rank(f::FuncOp) = (length(f.args) == 1 ? family_rank(f.args[1]) : 90)

# Opaque wrapper to treat a QSum as an operator argument to functions
struct SumOperator <: AbstractQuantumObject
    expr::QSum
end

# Determine if a QSum is homogeneous over a single operator family
function _homogeneous_family(s::QSum)
    fam = nothing
    for t in s.terms
        fs = t.factors
        # terms with no factors (pure scalar) don't affect family
        isempty(fs) && continue
        for f in fs
            # derive symbol for family
            sym = f isa FuncOp && length(f.args) == 1 ? _family_symbol(f.args[1]) : _family_symbol(f)
            if sym === nothing
                return nothing
            end
            if fam === nothing
                fam = sym
            elseif fam != sym
                return nothing
            end
        end
    end
    return fam
end

_family_symbol(::FuncOp) = :generic
_family_symbol(s::SumOperator) = _homogeneous_family(getfield(s, :expr))
_family_symbol(::IdentityOperator) = :identity

# Specialize for known base operator families
_family_symbol(::Type{T}) where {T} = :generic
_family_symbol(x::AbstractQuantumObject) = begin
    x isa SumOperator && return _homogeneous_family(getfield(x, :expr))
    if x isa FuncOp && length(getfield(x, :args)) == 1
        return _family_symbol(getfield(x, :args)[1])
    end
    if nameof(typeof(x)) == :XOp
        return :x
    elseif nameof(typeof(x)) == :POp
        return :p
    elseif nameof(typeof(x)) == :BosonicOperator
        return :b
    elseif nameof(typeof(x)) == :FermionicOperator
        return :c
    elseif x isa IdentityOperator
        return :identity
    else
        return :generic
    end
end

# Family rank for SumOperator: inherit rank if homogeneous, else treat as generic
function family_rank(s::SumOperator)
    fam = _homogeneous_family(getfield(s, :expr))
    if fam === :x || fam === :p
        return 20
    elseif fam === :c
        return 30
    elseif fam === :b
        return 40
    else
        return 95
    end
end

# Commutation trait: by default, cross-family commute; override for special cases
commutes_across_families(::AbstractQuantumObject) = true
function commutes_across_families(f::FuncOp)
    if length(getfield(f, :args)) == 1
        return commutes_across_families(getfield(f, :args)[1])
    end
    return true
end
function commutes_across_families(s::SumOperator)
    # Non-commuting unless homogeneous single-family
    return _homogeneous_family(getfield(s, :expr)) !== nothing
end

# qmul_terms for mixed QTerm concatenates and stably sorts by family_rank
function qmul_terms(t1::QTerm, t2::QTerm)
    coeff = t1.coeff * t2.coeff
    fs = vcat(t1.factors, t2.factors)
    # If any factor is marked non-commuting, preserve original order
    if any(!commutes_across_families(f) for f in fs)
        return [QTerm(coeff, fs)]
    end
    # Otherwise, stable rank-based order: sort by (rank, original index)
    pairs = [(family_rank(f), i, f) for (i, f) in enumerate(fs)]
    sort!(pairs)
    fs_sorted = [p[3] for p in pairs]
    return [QTerm(coeff, fs_sorted)]
end

# ---------- Generic algebra over sums ----------

# Fallback for term multiplication; specialized per family
qmul_terms(t1, t2) = error("qmul_terms not implemented for term type $(typeof(t1))")

# Addition for sums
Base.:+(a::S, b::S) where {S<:AbstractQSum} = begin
    ST = typeof(a)
    ST(combine_like_terms!(vcat(getfield(a, :terms), getfield(b, :terms))))
end

# Negation/subtraction for sums
Base.:-(x::S) where {S<:AbstractQSum} = begin
    terms = getfield(x, :terms)
    T = eltype(terms)
    ST = typeof(x)
    ST([T(-getfield(t, :coeff), getfield(t, :factors)) for t in terms])
end
Base.:-(a::S, b::S) where {S<:AbstractQSum} = a + (-b)

# Multiplication for sums
Base.:*(a::S, b::S) where {S<:AbstractQSum} = begin
    terms_a = getfield(a, :terms)
    terms_b = getfield(b, :terms)
    T = eltype(terms_a)
    acc = T[]
    for t1 in terms_a
        for t2 in terms_b
            append!(acc, qmul_terms(t1, t2))
        end
    end
    ST = typeof(a)
    ST(combine_like_terms!(acc))
end

# Mixing with scalars inside sums
Base.:+(a::S, b::Scalar) where {S<:AbstractQSum} = a + typeof(a)(b)
Base.:+(a::Scalar, b::S) where {S<:AbstractQSum} = typeof(b)(a) + b
Base.:*(a::Scalar, b::S) where {S<:AbstractQSum} = begin
    T = eltype(getfield(b, :terms))
    typeof(b)([T(getfield(t, :coeff) * a, getfield(t, :factors)) for t in getfield(b, :terms)])
end
Base.:*(a::S, b::Scalar) where {S<:AbstractQSum} = b * a

# Mixing with single factors (operators)
Base.:+(a::S, b::AbstractQuantumObject) where {S<:AbstractQSum} = a + typeof(a)(b)
Base.:+(a::AbstractQuantumObject, b::S) where {S<:AbstractQSum} = typeof(b)(a) + b
Base.:*(a::S, b::AbstractQuantumObject) where {S<:AbstractQSum} = a * typeof(a)(b)
Base.:*(a::AbstractQuantumObject, b::S) where {S<:AbstractQSum} = typeof(b)(a) * b

# Mixing at operator level: allow O + x where x is a scalar or Symbolics variable
Base.:+(a::AbstractQuantumObject, b::Scalar) = QSum(a) + QSum(IdentityOperator(b))
Base.:+(a::Scalar, b::AbstractQuantumObject) = QSum(IdentityOperator(a)) + QSum(b)

# Multiplication at operator level: non-expanding single-term QSum
Base.:*(a::Scalar, b::AbstractQuantumObject) = QSum([QTerm(a, AbstractQuantumObject[b])])
Base.:*(a::AbstractQuantumObject, b::Scalar) = QSum([QTerm(b, AbstractQuantumObject[a])])
Base.:*(a::AbstractQuantumObject, b::AbstractQuantumObject) = QSum([QTerm(one(Int), AbstractQuantumObject[a, b])])

# Generic adjoint for quantum objects: by default, return the object unchanged.
# Specific operator families override this to toggle creation/annihilation.
Base.adjoint(op::AbstractQuantumObject) = op

# Builders
fop(f, ops::AbstractQuantumObject...) = FuncOp(f, AbstractQuantumObject[ops...])

# Mixed builder: allow scalars and QSum alongside operators; wrap scalars and sums
fop(f, args::Union{Scalar,AbstractQuantumObject,QSum}...) = begin
    converted = AbstractQuantumObject[]
    for a in args
        if a isa AbstractQuantumObject
            push!(converted, a)
        elseif a isa QSum
            push!(converted, SumOperator(a))
        else
            push!(converted, IdentityOperator(a))
        end
    end
    FuncOp(f, converted)
end

# Pretty print as f(arg1, arg2, ...); special-case power
_needs_pow_parens(base::AbstractQuantumObject) = base isa SumOperator
Base.show(io::IO, f::FuncOp) = begin
    if f.fname == :pow && length(f.args) == 2
        base, exp = f.args[1], f.args[2]
        # Prefer Unicode superscript for integer exponents (supports IdentityOperator-wrapped ints)
        if (exp isa IdentityOperator && exp.var isa Integer)
            if _needs_pow_parens(base)
                print(io, "(", base, ")", superscript_digits(exp.var))
            else
                print(io, base, superscript_digits(exp.var))
            end
        elseif exp isa Integer
            if _needs_pow_parens(base)
                print(io, "(", base, ")", superscript_digits(exp))
            else
                print(io, base, superscript_digits(exp))
            end
        else
            if _needs_pow_parens(base)
                print(io, "(", base, ")^", exp)
            else
                print(io, base, "^", exp)
            end
        end
        return
    end
    fname = f.fname
    fname_str = fname isa Symbol ? String(fname) : fname isa String ? fname : string(fname)
    print(io, fname_str, "(")
    for (i, a) in enumerate(f.args)
        i > 1 && print(io, ", ")
        print(io, a)
    end
    print(io, ")")
end

# Show for SumOperator: display the inner sum; parentheses intentionally omitted here
Base.show(io::IO, s::SumOperator) = show(io, getfield(s, :expr))

# If Symbolics function variables are available, allow f(op1, op2, ...) where f is symbolic
try
    if isdefined(Symbolics, :FnType)
        @eval (f::Symbolics.FnType)(ops::AbstractQuantumObject...) = $(Expr(:quote, :(fop(f, ops...))))
    end
catch
end

# Overloads for common mathematical functions to produce FuncOp when applied to operators
for fname in (:sin, :cos, :tan, :exp)
    @eval begin
        Base.$fname(x::AbstractQuantumObject) = fop($(QuoteNode(fname)), x)
        Base.$fname(x::QSum) = fop($(QuoteNode(fname)), x)
    end
end

# Power overloads
# x ^ (scalar) -> wrap exponent as IdentityOperator and build FuncOp directly
Base.:^(x::AbstractQuantumObject, y::Scalar) = FuncOp(:pow, AbstractQuantumObject[x, IdentityOperator(y)])
# x ^ (operator) -> use fop to build a two-arg function-of-operators
Base.:^(x::AbstractQuantumObject, y::AbstractQuantumObject) = fop(:pow, x, y)
# Sum ^ (scalar): treat sum as an operator via SumOperator
Base.:^(x::QSum, y::Scalar) = FuncOp(:pow, AbstractQuantumObject[SumOperator(x), IdentityOperator(y)])

# Common helper to robustly detect zero-like coefficients
_iszero_coeff(x) = try
    iszero(x)
catch
    false
end

# Robust checks for exact ±1 coefficients that won't error with symbolic types
_isone_coeff(x) = try
    r = (x == 1)
    r === true
catch
    false
end
_isnegone_coeff(x) = try
    r = (x == -1)
    r === true
catch
    false
end

# ---------- Generic utilities to reduce duplication across operator families ----------

# Encode a factor into a canonical key for combining like terms.
encode_factor(f::AbstractQuantumObject) = (:s, sprint(show, f))
encode_factor(f::FuncOp) = (:f, string(f.fname), [encode_factor(a) for a in f.args])
encode_factor(f::QTerm) = Tuple((encode_factor(x) for x in f.factors))

# Combine like terms for any term type with fields (coeff, factors)
function combine_like_terms!(terms::Vector{T}) where {T}
    dict = Dict{Any, Scalar}()
    order = Dict{Any, Int}()
    reps = Dict{Any, Any}()
    idx = 0
    for t in terms
        _iszero_coeff(getfield(t, :coeff)) && continue
        fs = getfield(t, :factors)
        k = Tuple((encode_factor(f) for f in fs))
        if haskey(dict, k)
            dict[k] = dict[k] + getfield(t, :coeff)
        else
            dict[k] = getfield(t, :coeff)
            idx += 1
            order[k] = idx
            reps[k] = fs
        end
    end
    out = T[]
    for (k, c) in sort(collect(dict); by = x -> order[x[1]])
        _iszero_coeff(c) && continue
        push!(out, T(c, reps[k]))
    end
    return out
end

# Pretty-printer for any sum type with field .terms containing terms of (coeff, factors)
function show_qsum(io::IO, s)
    terms = getfield(s, :terms)
    filtered = Any[]
    for t in terms
        coeff = getfield(t, :coeff)
        facs = getfield(t, :factors)
        _iszero_coeff(coeff) && isempty(facs) && continue
        push!(filtered, (coeff, facs))
    end
    if isempty(filtered)
        return print(io, 0)
    end
    isfirst = true
    for tf in filtered
        coeff, facs = tf
        if isfirst
            isfirst = false
        else
            print(io, " + ")
        end
        if isempty(facs)
            print(io, coeff)
        else
            if _isone_coeff(coeff)
                # no coefficient
            elseif _isnegone_coeff(coeff)
                print(io, "-")
            else
                print(io, coeff, " ")
            end
            # Print factors with compression of adjacent identical factors: a a a -> a^3
            i = 1
            first_factor = true
            prev_was_sum = false
            while i <= length(facs)
                f = facs[i]
                shown = sprint(show, f)
                cnt = 1
                j = i + 1
                while j <= length(facs)
                    if sprint(show, facs[j]) == shown
                        cnt += 1
                        j += 1
                    else
                        break
                    end
                end
                # Determine if current group involves a SumOperator (for parentheses and separator)
                curr_is_sum = f isa SumOperator
                # Separator: use " * " when adjacent to a SumOperator, else a single space
                if !first_factor
                    if prev_was_sum || curr_is_sum
                        print(io, " * ")
                    else
                        print(io, " ")
                    end
                end
                # Wrap SumOperator in parentheses when in product context
                if curr_is_sum
                    print(io, "(", shown, ")")
                else
                    print(io, shown)
                end
                if cnt > 1
                    print(io, "^", cnt)
                end
                first_factor = false
                prev_was_sum = curr_is_sum
                i = j
            end
        end
    end
end

# ---------- Formatting helpers: subscripts for indices, conjugate symbol toggle ----------

const _digit_to_sub = Dict(
    '0'=>'₀','1'=>'₁','2'=>'₂','3'=>'₃','4'=>'₄','5'=>'₅','6'=>'₆','7'=>'₇','8'=>'₈','9'=>'₉','-'=>'₋'
)

subscript_digits(n::Integer) = join(_digit_to_sub[c] for c in string(n))
subscript_index(idx) = idx isa Integer ? subscript_digits(idx) : string('₍', string(idx), '₎')

# Superscript digits for powers
const _digit_to_super = Dict(
    '0'=>'⁰','1'=>'¹','2'=>'²','3'=>'³','4'=>'⁴','5'=>'⁵','6'=>'⁶','7'=>'⁷','8'=>'⁸','9'=>'⁹','-'=>'⁻'
)
superscript_digits(n::Integer) = join(_digit_to_super[c] for c in string(n))

const _conjugate_style = Ref(:apostrophe)  # :apostrophe | :dagger

function set_conjugate_style!(style::Symbol)
    style in (:apostrophe, :dagger) || error("Invalid conjugate style: $(style). Use :apostrophe or :dagger.")
    _conjugate_style[] = style
    return style
end

use_apostrophe!() = set_conjugate_style!(:apostrophe)
use_dagger!() = set_conjugate_style!(:dagger)
get_conjugate_style() = _conjugate_style[]

superscript_dagger() = (_conjugate_style[] === :apostrophe ? "'" : "†")

Base.show(io::IO, s::QSum) = show_qsum(io, s)

# Promotions and ops for cross-family commuting
_to_qsum(x::AbstractQuantumObject) = QSum(x)
_to_qsum(x::Scalar) = QSum(x)
_to_qsum(x::QSum) = x

Base.:+(a::QSum, b::QSum) = QSum(combine_like_terms!(vcat(a.terms, b.terms)))
# Non-expanding product for sums: keep as a single unevaluated product
Base.:*(a::QSum, b::QSum) = QSum([QTerm(one(Int), AbstractQuantumObject[SumOperator(a), SumOperator(b)])])
Base.:*(a::QSum, b::AbstractQuantumObject) = QSum([QTerm(one(Int), AbstractQuantumObject[SumOperator(a), b])])
Base.:*(a::AbstractQuantumObject, b::QSum) = QSum([QTerm(one(Int), AbstractQuantumObject[a, SumOperator(b)])])

# Generic addition fallback: any two operators produce a QSum
Base.:+(a::AbstractQuantumObject, b::AbstractQuantumObject) = _to_qsum(a) + _to_qsum(b)

# ---------- Expansion utilities ----------

export expand

"""
    expand(expr)

Distribute products over sums and expand powers of sums when the exponent is an integer.
Does not perform any normal ordering or simplification beyond distribution.
Returns a QSum.
"""
expand(x::AbstractQuantumObject) = QSum(x)
expand(s::QSum) = begin
    acc = QTerm[]
    for t in s.terms
        append!(acc, _expand_term(t))
    end
    QSum(combine_like_terms!(acc))
end

function _expand_term(t::QTerm)
    return _expand_factors(t.coeff, getfield(t, :factors))
end

function _expand_factors(coeff::Scalar, factors::Vector{AbstractQuantumObject})
    partials = [QTerm(coeff, AbstractQuantumObject[])]
    for f in factors
        if f isa SumOperator
            news = QTerm[]
            s = getfield(f, :expr)
            for p in partials
                for inner in s.terms
                    newcoeff = p.coeff * inner.coeff
                    newfacs = vcat(p.factors, inner.factors)
                    push!(news, QTerm(newcoeff, newfacs))
                end
            end
            partials = news
        elseif f isa FuncOp && getfield(f, :fname) == :pow && length(getfield(f, :args)) == 2 && (getfield(f, :args)[1] isa SumOperator)
            base = getfield(f, :args)[1]::SumOperator
            exp = getfield(f, :args)[2]
            n = exp isa IdentityOperator ? exp.var : exp
            if n isa Integer && n >= 0
                # Expand (sum)^n by repeated distribution
                pow_terms = [QTerm(one(Int), AbstractQuantumObject[])]
                sum_terms = getfield(base, :expr).terms
                for k in 1:n
                    next_terms = QTerm[]
                    for pt in pow_terms
                        for st in sum_terms
                            push!(next_terms, QTerm(pt.coeff * st.coeff, vcat(pt.factors, st.factors)))
                        end
                    end
                    pow_terms = next_terms
                end
                # Merge pow_terms into partials
                news = QTerm[]
                for p in partials
                    for q in pow_terms
                        push!(news, QTerm(p.coeff * q.coeff, vcat(p.factors, q.factors)))
                    end
                end
                partials = news
            else
                # Non-integer exponent: keep as opaque factor
                for p in partials
                    push!(p.factors, f)
                end
            end
        else
            for p in partials
                push!(p.factors, f)
            end
        end
    end
    return partials
end
