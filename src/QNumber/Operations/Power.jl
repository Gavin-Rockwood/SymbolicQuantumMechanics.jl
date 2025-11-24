function Base.:^(a::QNumber, n::Union{Num,Number})
    iszero(n) && return 1
    isone(n) && return a
    return QPow(a, n)
end