function Base.show(io::IO, q::QNumber)
    str = get_string(q)
    print(io, str)
end

function fshow(x::QNumber)
    return (latexstring(get_string(x)))
end