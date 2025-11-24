"""
Canonical position/momentum operators with [x_i, p_j] = i*δ(i,j) (ħ=1).

All addition/multiplication between AbstractQuantumObjects uses QSum; SumC is removed.
"""

# Reuse δ(..) and _kdelta from BosonicOperator.jl

# Basic operators (self-adjoint)
struct XOp <: AbstractQuantumObject
    index::Any
end
struct POp <: AbstractQuantumObject
    index::Any
end

# Constructors note: single-letter forms removed; use XOp(i), POp(i)

family_rank(::XOp) = 20
family_rank(::POp) = 20

# One-arg function builders delegate to generic FuncOp
fx(f, op::XOp) = fop(f, op)
fp(f, op::POp) = fop(f, op)

# Pretty printing
Base.show(io::IO, op::XOp) = print(io, "x", subscript_index(op.index))
Base.show(io::IO, op::POp) = print(io, "p", subscript_index(op.index))

# Canonical-like factors (for local algorithms): include FuncOp; multi-arg funcs are opaque
const CanonLike = Union{XOp, POp, FuncOp}

_is_x_like(f) = (f isa XOp) || (f isa FuncOp && length(f.args) == 1 && (f.args[1] isa XOp))
_is_p_like(f) = (f isa POp) || (f isa FuncOp && length(f.args) == 1 && (f.args[1] isa POp))

# Multiply two ordered lists of canonical-like factors and produce QTerm vectors after normal-ordering
function _normal_order_terms_c(coeff::Scalar, factors::Vector{CanonLike})::Vector{Tuple{Scalar,Vector{CanonLike}}}
    results = [(coeff, factors)]
    while true
        changed = false
        new_results = Tuple{Scalar, Vector{CanonLike}}[]
        for (c, fs) in results
            i = 1
            local progressed = false
            while i < length(fs)
                left = fs[i]
                right = fs[i+1]
                if _is_x_like(left) && _is_p_like(right)
                    # X_i P_j -> P_j X_i + i*δ(i,j) (ħ=1)
                    swapped = copy(fs)
                    swapped[i], swapped[i+1] = swapped[i+1], swapped[i]
                    push!(new_results, (c, swapped))
                    li = left isa XOp ? left.index : (left::FuncOp).args[1]::XOp |> x->x.index
                    rj = right isa POp ? right.index : (right::FuncOp).args[1]::POp |> x->x.index
                    push!(new_results, (c * (im * _kdelta(li, rj)), vcat(fs[1:i-1], fs[i+2:end])))
                    changed = true
                    progressed = true
                    break
                else
                    i += 1
                end
            end
            if !progressed
                push!(new_results, (c, fs))
            end
        end
        changed || return new_results
        results = new_results
    end
end

# Public API: canonical normal ordering returning QSum
normal_order_c(x::CanonLike) = begin
    terms = _normal_order_terms_c(one(Int), CanonLike[x])
    QSum([QTerm(c, AbstractQuantumObject[factors...]) for (c, factors) in terms])
end
normal_order_c(s::QSum) = begin
    acc_terms = QTerm[]
    for t in s.terms
        # Validate only canonical-like factors are present
        facs = CanonLike[]
        for f in t.factors
            f isa CanonLike || error("normal_order_c(::QSum) requires only canonical-like factors")
            push!(facs, f)
        end
        for (c, fs) in _normal_order_terms_c(t.coeff, facs)
            push!(acc_terms, QTerm(c, AbstractQuantumObject[fs...]))
        end
    end
    QSum(combine_like_terms!(acc_terms))
end

# Local multiplication when both sides are canonical-like: return QSum
Base.:*(a::CanonLike, b::CanonLike) = begin
    vt = _normal_order_terms_c(one(Int), CanonLike[a, b])
    QSum([QTerm(c, AbstractQuantumObject[fs...]) for (c, fs) in vt])
end

# Addition across canonical-like factors continues to use generic QSum
Base.:+(a::CanonLike, b::CanonLike) = QSum(a) + QSum(b)

# Scalars mix via generic QSum rules; no SumC-specific overloads remain

# Powers are represented via FuncOp(:pow, base, exponent); handled generically
