# Fermionic operators integrated with Symbolics.jl

# Reuse δ(..) and _kdelta from BosonicOperator.jl

struct FermionicOperator <: AbstractQuantumObject
    index::Any
    dag::Bool
end

# Note: single-letter constructor `c(i)` was removed.
# Expose convenience constructors:
#   FOp(i) -> annihilation operator c_i
#   adjoint(FOp(i)) -> creation operator c'ᵢ
FOp(i) = FermionicOperator(i, false)
dag(op::FermionicOperator) = FermionicOperator(op.index, !op.dag)
Base.adjoint(op::FermionicOperator) = dag(op)

family_rank(::FermionicOperator) = 30

# Single-arg function-of-fermion behaves like c (annihilation-like)
fop(f, op::FermionicOperator) = FuncOp(f, AbstractQuantumObject[op]);

Base.show(io::IO, op::FermionicOperator) = begin
    if op.dag
        print(io, "c", superscript_dagger(), subscript_index(op.index))
    else
        print(io, "c", subscript_index(op.index))
    end
end

const FermiLike = Union{FermionicOperator, FuncOp}

struct FTerm
    coeff::Scalar
    factors::Vector{FermiLike}
end

struct FSum <: AbstractQSum
    terms::Vector{FTerm}
end

FSum() = FSum(FTerm[])
FSum(c::Scalar) = FSum([FTerm(c, FermiLike[])])
FSum(op::FermiLike) = FSum([FTerm(one(Int), [op])])

function encode_factor(f::FermiLike)
    f isa FermionicOperator && return (:c, f.dag, f.index)
    f isa FuncOp && return (:f, string(f.fname), [encode_factor(a) for a in f.args])
    return (:s, sprint(show, f))
end

_combine_like_f!(terms::Vector{FTerm}) = combine_like_terms!(terms)

Base.show(io::IO, s::FSum) = show_qsum(io, s)

# Promotions
_to_sum_f(x::FermiLike) = FSum(x)
_to_sum_f(x::Scalar) = FSum(x)
_to_sum_f(x::FSum) = x

# Unify addition to generic QSum for all operator families
Base.:+(a::FermiLike, b::FermiLike) = QSum(a) + QSum(b)

# Local multiplication for fermions: immediately normal-order and return FSum
Base.:*(a::FermiLike, b::FermiLike) = begin
    vt = _normal_order_terms_f(one(Int), FermiLike[a, b])
    FSum(vt)
end

qmul_terms(t1::FTerm, t2::FTerm) = _mul_terms_f(t1, t2)

# Fermionic normal ordering: bring all creation operators (cd) left of annihilation (c), capturing signs
# Using {c_i, cd_j} = δ(i,j) => c_i cd_j = δ(i,j) - cd_j c_i
function _mul_terms_f(t1::FTerm, t2::FTerm)
    coeff = t1.coeff * t2.coeff
    factors = vcat(t1.factors, t2.factors)
    return _normal_order_terms_f(coeff, factors)
end

_is_annih_f(f) = (f isa FermionicOperator && !f.dag) || (f isa FuncOp && length(f.args) == 1 && (f.args[1] isa FermionicOperator) && !(f.args[1]::FermionicOperator).dag)
_is_create_f(f) = (f isa FermionicOperator && f.dag)

function _normal_order_terms_f(coeff::Scalar, factors::Vector{FermiLike})::Vector{FTerm}
    results = [(coeff, factors)]
    while true
        changed = false
        new_results = Tuple{Scalar, Vector{FermiLike}}[]
        for (c, fs) in results
            i = 1
            local progressed = false
            while i < length(fs)
                left = fs[i]; right = fs[i+1]
                if _is_annih_f(left) && _is_create_f(right)
                    # c_i cd_j -> - cd_j c_i + δ(i,j)
                    swapped = copy(fs)
                    swapped[i], swapped[i+1] = swapped[i+1], swapped[i]
                    push!(new_results, (-c, swapped))
                    # delta term
                    li = left isa FermionicOperator ? left.index : (left::FuncOp).args[1]::FermionicOperator |> x->x.index
                    push!(new_results, (c * _kdelta(li, (right::FermionicOperator).index), vcat(fs[1:i-1], fs[i+2:end])))
                    changed = true
                    progressed = true
                    break
                elseif (_is_create_f(left) && _is_create_f(right)) || (_is_annih_f(left) && _is_annih_f(right))
                    # Do not reorder identical types during normal ordering to avoid infinite toggling.
                    # Keep their relative order unchanged; no sign change needed.
                    i += 1
                else
                    i += 1
                end
            end
            if !progressed
                push!(new_results, (c, fs))
            end
        end
        changed || return [FTerm(c, fs) for (c, fs) in new_results]
        results = new_results
    end
end

normal_order_f(x::FermiLike) = FSum(x)
normal_order_f(x::FSum) = x

# Allow normal_order_f over a QSum when it contains only fermionic-like factors
normal_order_f(s::QSum) = begin
    terms_acc = FTerm[]
    for t in s.terms
        facs = FermiLike[]
        for f in t.factors
            f isa FermiLike || error("normal_order_f(::QSum) requires only fermionic-like factors")
            push!(facs, f)
        end
        # Apply fermionic normal-ordering per term
        ordered_terms = _normal_order_terms_f(t.coeff, facs)
        append!(terms_acc, ordered_terms)
    end
    FSum(combine_like_terms!(terms_acc))
end
