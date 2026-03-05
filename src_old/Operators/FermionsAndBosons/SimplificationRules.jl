function anticommute_fermions_and_commute_bosons(x)
    TYPECHECK = Union{Boson, Fermion}
    if x isa QMul
        args = copy(x.args_nc)
        coeff = x.arg_c
        #println("Applying anticommutation/commutation simplification...")

        for i in 1:length(args)-1
            # println("Checking operators at positions $i and $(i+1)...")
            op1 = args[i]
            op2 = args[i+1]
            # println("Operator 1: $op1")
            # println("Operator 2: $op2")
            # only indistinguishable fermions should anticommute
            if op1 isa TYPECHECK && op2 isa typeof(op1)  && (isequal(op1.name, op2.name))
                # Same fermion operator (including position and dag state) -> annihilate
                if isequal(op1, op2)
                    # println("Operators are identical, simplifying to zero.")
                    return 0

                else
                    # println("Operators are different states, checking order...")
                    if (!op1.dag && op2.dag)  # annihilation * creation
                        # println("Different Dagger state, applying (anti)commutation relation...")
                        # f_i * f_j' = delta(i,j) - f_j' * f_i (Standard Anticommutation)
                        loc1 = op1.at == nothing ? '∅' : op1.at
                        loc2 = op2.at == nothing ? '∅' : op2.at
                        if isequal(loc1, loc2)
                            δ = 1
                        else
                            @variables δ(loc1, loc2)
                        end

                        pm = op1 isa Fermion ? -1 : 1
                        # Remove these two operators and add delta term
                        new_args = vcat(args[1:i-1], args[i+2:end])
                        delta_term = coeff * δ
                        swap_term = pm * coeff

                        if isempty(new_args)
                            # Just the delta and the swap term
                            return delta_term + QMul(swap_term, [op2, op1])
                        else
                            return QMul(delta_term, new_args) + QMul(swap_term, vcat(new_args[1:i-1], [op2, op1], new_args[i:end]))
                        end
                    elseif op1.dag == op2.dag  # both creation or both annihilation
                        # println("Same Dagger state, swapping operators...")
                        pm = op1 isa Fermion ? -1 : 1
                        args[i] = op2
                        args[i+1] = op1
                        coeff = pm *coeff
                        return QMul(coeff, args)
                    end
                end
            end
        end
    end
    return x
end
push!(QuantumSimplificationRules, anticommute_fermions_and_commute_bosons)

function normal_order_bosons_fermions(x)
    TYPECHECK = Union{Boson, Fermion}
    if x isa QMul
        args = copy(x.args_nc)
        coeff = x.arg_c

        for i in 1:length(args)-1
            op1 = args[i]
            op2 = args[i+1]

            # only distinguishable particles should be ordered
            if op1 isa TYPECHECK && op2 isa TYPECHECK && !(isequal(op1.name, op2.name))
                if op1<op2
                    args[i] = op2
                    args[i+1] = op1
                    return QMul(coeff, args)
                end
            end
        end
    end
    return x
end
push!(QuantumSimplificationRules, normal_order_bosons_fermions)

