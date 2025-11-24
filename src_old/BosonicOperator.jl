# Bosonic operators integrated with Symbolics.jl

# Kronecker delta as symbolic function with opportunistic evaluation
Symbolics.@variables δ(..)
_kdelta(i, j) = (i isa Integer && j isa Integer) ? (i == j ? one(Int) : zero(Int)) : δ(i, j)

# Bosonic operator types
struct BosonicOperator <: AbstractQuantumObject
    index::Any
    dag::Bool
end

# Note: single-letter constructor `b(i)` was removed.
# BOp(i) now constructs an annihilation operator b_i. Use BOp(i)' for creation.
BOp(i) = BosonicOperator(i, false)
dag(op::BosonicOperator) = BosonicOperator(op.index, !op.dag)
Base.adjoint(op::BosonicOperator) = dag(op)

# Family rank: lower means earlier in sorted product for cross-family commuting
# Function-of-boson delegates to generic FuncOp; treat only f(b) (annihilation-like) for now
fop(f, op::BosonicOperator) =  FuncOp(f, AbstractQuantumObject[op]);

Base.show(io::IO, op::BosonicOperator) = begin
    if op.dag
        print(io, "b", superscript_dagger(), subscript_index(op.index))
    else
        print(io, "b", subscript_index(op.index))
    end
end

# Scalars allowed in coefficients (numeric or Symbolics.Num) are defined in QuantumOperators.jl

# Any factor in a product can be a plain boson or any function-of-operator; multi-arg functions are opaque
const BoseLike = Union{BosonicOperator, FuncOp}

struct OpTerm
    coeff::Scalar
    factors::Vector{BoseLike}
end

struct OpSum <: AbstractQSum
    terms::Vector{OpTerm}
end

OpSum() = OpSum(OpTerm[])
OpSum(c::Scalar) = OpSum([OpTerm(c, BoseLike[])])
OpSum(op::BoseLike) = OpSum([OpTerm(one(Int), [op])])

# Internal helpers
_key_factor(f::BosonicOperator) = (:b, f.dag, f.index)
_key_factor(f::FuncOp) = (:f, string(f.fname), [_key_factor(a) for a in f.args])
function encode_factor(f::BoseLike)
    f isa BosonicOperator && return (:b, f.dag, f.index)
    f isa FuncOp && return (:f, string(f.fname), [encode_factor(a) for a in f.args])
    return (:s, sprint(show, f))
end


_combine_like!(terms::Vector{OpTerm}) = combine_like_terms!(terms)

Base.show(io::IO, s::OpSum) = show_qsum(io, s)

# Promote inputs to OpSum
_to_sum(x::BoseLike) = OpSum(x)
_to_sum(x::Scalar) = OpSum(x)
_to_sum(x::OpSum) = x

# Unify addition to generic QSum for all operator families
Base.:+(a::BoseLike, b::BoseLike) = QSum(a) + QSum(b)

# Local multiplication for bosons: immediately normal-order and return OpSum
Base.:*(a::BoseLike, b::BoseLike) = begin
    vt = _normal_order_terms(one(Int), BoseLike[a, b])
    OpSum(vt)
end

qmul_terms(t1::OpTerm, t2::OpTerm) = _mul_terms(t1, t2)

# Multiply two terms and normal-order
function _mul_terms(t1::OpTerm, t2::OpTerm)
    coeff = t1.coeff * t2.coeff
    factors = vcat(t1.factors, t2.factors)
    return _normal_order_terms(coeff, factors)
end

# Core: normal ordering using [b_i, bd_j] = δ(i,j), other commutators zero
function _normal_order_terms(coeff::Scalar, factors::Vector{BoseLike})::Vector{OpTerm}
    results = [(coeff, factors)]
    while true
        changed = false
        new_results = Tuple{Scalar, Vector{BoseLike}}[]
        for (c, fs) in results
            i = 1
            local progressed = false
            while i < length(fs)
                left = fs[i]
                right = fs[i+1]
                is_annih_left = (left isa BosonicOperator && !left.dag) || (left isa FuncOp && length(left.args) == 1 && (left.args[1] isa BosonicOperator) && !(left.args[1]::BosonicOperator).dag)
                is_create_right = (right isa BosonicOperator && right.dag)
                if is_annih_left && is_create_right
                    # b_i bd_j -> bd_j b_i + δ(i,j)
                    swapped = copy(fs)
                    swapped[i], swapped[i+1] = swapped[i+1], swapped[i]
                    push!(new_results, (c, swapped))
                    reduced = vcat(fs[1:i-1], fs[i+2:end])
                    li = left isa BosonicOperator ? left.index : (left::FuncOp).args[1]::BosonicOperator |> x->x.index
                    push!(new_results, (c * _kdelta(li, right.index), reduced))
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
        changed || return [OpTerm(c, fs) for (c, fs) in new_results]
        results = new_results
    end
end

# Optional: convenience
normal_order(x::BoseLike) = OpSum(x)
normal_order(x::OpSum) = x

# Allow normal_order over a QSum when it contains only bosonic-like factors
normal_order(s::QSum) = begin
    acc = OpTerm[]
    for t in s.terms
        # Validate and collect factors per term
        facs = BoseLike[]
        for f in t.factors
            f isa BoseLike || error("normal_order(::QSum) requires only bosonic-like factors")
            push!(facs, f)
        end
        # Apply bosonic normal-ordering algorithm to this term
        ordered_terms = _normal_order_terms(t.coeff, facs)
        append!(acc, ordered_terms)
    end
    OpSum(combine_like_terms!(acc))
end
