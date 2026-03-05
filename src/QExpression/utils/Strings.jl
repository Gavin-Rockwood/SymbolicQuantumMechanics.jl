function Base.string(q::QSymbol; in_prog=false)
    str = "$(q.name)"
    if !isequal(q.at, nothing)
        str *= "_$(q.at)"
    end
    if q.dag
        str *= raw"^\dagger"
    end
    if in_prog
        return str
    else
        return raw"$" * str * raw"$"
    end
end
function Base.string(q::QMul; in_prog=false)
    str_nc = ""
    str_c = ""
    mul_is_ID = false
    if length(q.args_nc) == 1 && isequal(q.args_nc[1], Identity())
        mul_is_ID = true
    end

    if !SymbolicUtils._isone(q.arg_c)
        if typeof(q.arg_c) <: Num
            if iscall(q.arg_c.val) && !mul_is_ID
                if operation(q.arg_c.val) == +
                    str_c *= "\\left("
                end
            end
        end
        str_c *= string(q.arg_c) * ""
        if typeof(q.arg_c) <: Num
            if iscall(q.arg_c.val) && !mul_is_ID
                if operation(q.arg_c.val) == +
                    str_c *= "\\right)"
                end
            end
        end
    end
    if mul_is_ID
        str_nc *= " "
    else
        for arg in q.args_nc
            if typeof(arg) <: QAdd
                str_nc *= "\\left("
            end
            str_nc *= string(arg; in_prog=true)
            if typeof(arg) <: QAdd
                str_nc *= "\\right)"
            end
            str_nc *= " "
        end
    end
    if str_c == "1"
        str_c = ""
    elseif str_c == "-1" && !mul_is_ID
        str_c = "-"
    end
    str = str_c * str_nc
    if in_prog
        return str
    else
        return raw"$" * str * raw"$"
    end
end

function Base.string(q::QAdd; in_prog=false)
    str = ""
    for i in 1:length(q.arguments)
        arg = q.arguments[i]
        new_bit = string(arg; in_prog=true)
        if new_bit[1] == '-'
            str = str[1:end-2]
        end
        str *= new_bit
        if i < length(q.arguments)
            str *= " + "
        end
    end
    if in_prog
        return str
    else
        return raw"$" * str * raw"$"
    end
end

function Base.string(q::QPow; in_prog=false)
    is_add = typeof(q.x) <: QAdd ? true : false
    str = ""
    if is_add
        str *= raw"\left("
    end
    str *= string(q.x; in_prog=true)
    if is_add
        str *= raw"\right)"
    end
    str *= "^{" * string(q.y) * "}"

    if in_prog
        return str
    else
        return raw"$" * str * raw"$"
    end
end