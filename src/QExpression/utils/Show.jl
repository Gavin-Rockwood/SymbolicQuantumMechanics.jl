function Base.show(io::IO, q::QExpression)
    str = string(q)
    print(io, str)
end

function fshow(x::QExpression)
    return (latexstring(string(x)))
end