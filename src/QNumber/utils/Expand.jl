import Symbolics: expand

function expand(a::T, b::QAdd) where T<:QNumber
    terms = Any[a * b_ for b_ in arguments(b)]
    return sum(terms)
end
function expand(a::QAdd, b::T) where T<:QNumber
    terms = Any[a_ * b for a_ in arguments(a)]
    return sum(terms)
end
function expand(a::QAdd, b::QAdd)
    terms = Any[a_ * b_ for a_ in arguments(a) for b_ in arguments(b)]
    return sum(terms)
end
function expand(a::QNumber, b::QNumber)
    return a * b
end


function expand(x::QNumber; full=false)
    return x
end

function expand(a::QMul; full=false)
    arg_c = a.arg_c
    args_nc = a.args_nc

    b = args_nc[1]
    if full
        b = expand(b; full=full)
    end
    for i in 2:length(args_nc)
        if full
            b = expand(b, expand(args_nc[i]; full=full))
        else
            b = expand(b, args_nc[i])
        end

    end
    return arg_c * b
end
function expand(a::QAdd; full=false)
    new_args = []
    for i in 1:length(a.arguments)
        push!(new_args, expand(arguments(a)[i]; full=full))
    end
    return sum(new_args)
end

function expand(a::QPow; full=false)
    return QPow(expand(a.x; full=full), a.y)
end


function full_expand(x::QNumber)
    return expand(x; full=true)
end