using SymQM
using Test

use_apostrophe!()

@testset "Bosonic commutation and functions" begin
    # [b_i, bd_j] = δ(i,j)  (Note: BOp creates annihilation; use BOp(j)' for creation)
    @test string(normal_order(BosonicOperator(1, false)*BOp(1)')) == "b'₁ b₁ + 1"
    @test string(normal_order(BosonicOperator(1, false)*BOp(2)')) == "b'₂ b₁"

    # f(b) behaves like b
    @test string(fop(:g, BosonicOperator(2, false))*BOp(2)') == "b'₂ g(b₍2₎) + 1" || string(fop(:g, BosonicOperator(2, false))*BOp(2)') == "b'₂ g(b₂) + 1"
    @test occursin("b'₂ g(b₁)", string(fop(:g, BosonicOperator(1, false))*BOp(2)'))

    # Multi-arg function is opaque (no special reordering)
    s = string(fop(:h, BosonicOperator(1, false), BOp(1)')*BosonicOperator(1, false))
    @test occursin("h(b₁, b'₁) b₁", s) || occursin("h(b₍1₎, b'₍1₎) b₍1₎", s)
end

@testset "Symbolics compatibility" begin
    # Ensure Symbolics is available and we can create symbolic variables
    sym_ok = false
    try
        using Symbolics
        sym_ok = true
    catch
        @test true # if Symbolics isn't available, skip these checks
    end

    if sym_ok
        # Create a symbolic variable at runtime (avoid using the @variables macro so file parses)
        s = Symbolics.variable(:s)
        # Wrap a symbolic var with Identity when mixing
        id_s = Identity(s)

        # Apply trig/exponential functions to an operator and to an Identity-wrapped symbol
        op = XOp(1)
        @test string(sin(op)) == "sin(x₁)" || occursin("sin(x", string(sin(op)))
        @test string(cos(op)) == "cos(x₁)" || occursin("cos(x", string(cos(op)))
        @test string(exp(op)) == "exp(x₁)" || occursin("exp(x", string(exp(op)))

        @test string(sin(id_s)) == "sin(s)" || occursin("sin(s", string(sin(id_s)))

        # Mixing operator and symbolic variable: addition should succeed
        sum_q = op + s
        sstr = string(sum_q)
        @test occursin("x₁", sstr) || occursin("x_1", sstr)
        @test occursin("s", sstr)
    end

    # Always test functions applied to an operator, even without Symbolics
    op = XOp(1)
    @test string(sin(op)) == "sin(x₁)" || occursin("sin(x", string(sin(op)))
    @test string(cos(op)) == "cos(x₁)" || occursin("cos(x", string(cos(op)))
    @test string(exp(op)) == "exp(x₁)" || occursin("exp(x", string(exp(op)))
end

@testset "Type stability" begin
    # Bosonic
    @test @inferred(normal_order(BosonicOperator(1, false)*BOp(2))) isa OpSum
    @test @inferred(normal_order(BosonicOperator(1, false) + BOp(2))) isa OpSum
    # Canonical now returns QSum
    @test @inferred(normal_order_c(XOp(1)*POp(1))) isa QSum
    @test @inferred(normal_order_c(XOp(1) + POp(2))) isa QSum
    # Fermionic
    @test @inferred(normal_order_f(FermionicOperator(2, false)*FOp(2)')) isa FSum
    @test @inferred(normal_order_f(FermionicOperator(2, false) + FOp(3)')) isa FSum

    # Cross-family QSum type behavior
    qb = QSum(normal_order(BosonicOperator(1, false)*BOp(1)))
    qf = QSum(normal_order_f(FermionicOperator(1, false)*FOp(1)'))
    @test @inferred(qb * qf) isa QSum
    @test @inferred(qb + qf) isa QSum
end

@testset "Edge cases and robustness" begin
    # Multi-arg function-of-operator remains opaque and does not change families' rules
    s_b = fop(:H, BosonicOperator(1, false), BOp(2)') * BosonicOperator(3, false)
    sb_str = string(s_b)
    @test sb_str == "H(b₁, b'₂) b₃"

    s_c = fop(:K, XOp(1), POp(1)) * XOp(2)
    sc_str = string(s_c)
    @test sc_str == "K(x₁, p₁) x₂"

    s_f = fop(:J, FermionicOperator(1, false), FOp(2)') * FermionicOperator(3, false)
    sf_str = string(s_f)
    @test sf_str == "J(c₁, c'₂) c₃"

    # Scalar mixing with sums/products
    @test @inferred(2 * normal_order(BosonicOperator(1, false) + BOp(1))) isa OpSum
    @test @inferred(3im * normal_order_c(XOp(2)*POp(2))) isa QSum
    @test @inferred((-1) * normal_order_f(FermionicOperator(2, false) + FOp(2)')) isa FSum

    # Deep products requiring repeated normal-ordering steps
    deep_b = BosonicOperator(1, false)*BOp(2)'*BosonicOperator(2, false)*BOp(1)'
    db_str = string(normal_order(deep_b))
    @test db_str == "b'₂ b'₁ b₁ b₂ + b'₂ b₂"

    deep_f = FermionicOperator(1, false)*FOp(2)'*FermionicOperator(2, false)*FOp(1)'
    df_str = string(normal_order_f(deep_f))
    @test df_str == "-c'₂ c'₁ c₁ c₂ + c'₂ c₂"

    # QSum interactions with scalars
    qb = QSum(normal_order(BosonicOperator(1, false)))
    qf = QSum(normal_order_f(FermionicOperator(1, false)))
    @test @inferred(5 * qb + 2 * qf) isa QSum
end

@testset "Canonical commutation (ħ=1) and functions" begin
    # [x_i, p_j] = i δ(i,j) with ħ=1
    # Pretty-printer now hides "+ 0"
    s_cp11 = string(normal_order_c(XOp(1)*POp(1)))
    @test occursin("p₁ x₁", s_cp11) || occursin("p_1 x_1", s_cp11)
    @test occursin("1im", s_cp11)
    s_cp12 = string(normal_order_c(XOp(1)*POp(2)))
    @test occursin("p₂ x₁", s_cp12) || occursin("p_2 x_1", s_cp12)

    # f(x) behaves like x
    s_fx33 = string(fop(:f, XOp(3))*POp(3))
    @test occursin("p₃ f(x₃)", s_fx33) || occursin("p_3 f(x_3)", s_fx33)
    @test occursin("1im", s_fx33)
    s_fx12 = string(fop(:f, XOp(1))*POp(2))
    @test occursin("p₂ f(x₁)", s_fx12) || occursin("p_2 f(x_1)", s_fx12)

    # Multi-arg function is opaque
    s2 = string(fop(:F, XOp(2), POp(2))*XOp(2))
    @test occursin("F(x₂, p₂) x₂", s2) || occursin("F(x_2, p_2) x_2", s2)
end

@testset "Mixed boson/fermion expressions" begin
    # Bosonic sum/product in one expression
    exprB = normal_order(BosonicOperator(1, false)*BOp(1)' + BosonicOperator(2, false) + BOp(2)'*BosonicOperator(3, false))
    sb = sprint(show, exprB)
    @test occursin("b'₁ b₁ + 1", sb)
    @test occursin("b₂", sb)
    @test occursin("b'₂ b₃", sb)

    # Fermionic sum/product in one expression
    exprF = normal_order_f(FermionicOperator(1, false)*FOp(1)' + FermionicOperator(2, false) + FOp(2)'*FermionicOperator(3, false))
    sf = sprint(show, exprF)
    @test occursin("-c'₁ c₁ + 1", sf) || occursin("(-1) c'₁ c₁ + 1", sf)
    @test occursin("c₂", sf)
    @test occursin("c'₂ c₃", sf)

    # Function-of-operator mixed in
    @test occursin("b'₂ g(b", string(fop(:g, BosonicOperator(2, false))*BOp(2)')) && occursin("+ 1", string(fop(:g, BosonicOperator(2, false))*BOp(2)'))
    @test occursin("c'₃ h(c₃)", string(fop(:h, FermionicOperator(3, false))*FOp(3)')) && occursin("+ 1", string(fop(:h, FermionicOperator(3, false))*FOp(3)'))
end
