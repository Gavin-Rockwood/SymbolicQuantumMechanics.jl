function _can_combine(a,b)
    return false
end

function _can_combine(a::QNumber, b::QNumber)
    if isequal(a,b)
        return true
    end
    return false
end
function _combine(a::QNumber, b::QNumber)
    return QPow(a, 2; metadata=a.metadata)
end

function _can_combine(a::QNumber, b::QPow)
    if a == b.x
        return true
    end
    return false
end
function _combine(a::QNumber, b::QPow)
    new_exponent = b.y + 1
    return QPow(b.x, new_exponent; metadata=b.metadata)
end
function _can_combine(a::QPow, b::QNumber)
    if a.x == b
        return true
    end
    return false
end
function _combine(a::QPow, b::QNumber)
    new_exponent = a.y + 1
    return QPow(a.x, new_exponent; metadata=a.metadata)
end

function _can_combine(a::QPow, b::QPow)
    if a.x == b.x
        return true
    end
    return false
end
function _combine(a::QPow, b::QPow)
    new_exponent = a.y + b.y
    return QPow(a.x, new_exponent; metadata=a.metadata)
end


