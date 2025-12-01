function Base.:^(a::QNumber, n::Union{Num,Number})
    iszero(n) && return 1
    isone(n) && return a
    return QPow(a, n)
end

function Base.:^(a::QPow, n::Union{Num,Number})
    y = a.y*n
    iszero(y) && return 1
    isone(y) && return a
    return QPow(a.x, y; metadata=a.metadata)
end