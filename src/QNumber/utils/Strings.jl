function get_string(q::QSym; in_prog=false)
    str = "$(q.name)"
    if !isequal(q.at, nothing)
        str *= "_$(q.at)"
    end
    if in_prog
        return str
    else
        return raw"$" * str * raw"$"
    end
end
function get_string(q::QMul; in_prog=false)
    str = ""
    if !SymbolicUtils._isone(q.arg_c)
        if typeof(q.arg_c) <: Num
            if iscall(q.arg_c.val)
                if operation(q.arg_c.val) == +
                    str *= "\\left("
                end
            end
        end
        str *= string(q.arg_c) * ""
        if typeof(q.arg_c) <: Num
            if iscall(q.arg_c.val)
                if operation(q.arg_c.val) == +
                    str *= "\\right)"
                end
            end
        end
        str *= " "
    end
    if q.args_nc isa QNumber
        str *= get_string(q.args_nc; in_prog=true)
        str *= " "
    else
        for arg in q.args_nc
            if typeof(arg) <: QAdd
                str *= "\\left("
            end
            str *= get_string(arg; in_prog=true)
            if typeof(arg) <: QAdd
                str *= "\\right)"
            end
            str *= " "
        end
    end
    if in_prog
        return str
    else
        return raw"$" * str * raw"$"
    end
end

function get_string(q::QAdd; in_prog=false)
    str = ""
    for i in 1:length(q.arguments)
        arg = q.arguments[i]
        str *= get_string(arg; in_prog=true)
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

function get_string(q::QPow; in_prog=false)
    is_add = typeof(q.x) <: QAdd ? true : false
    str = ""
    if is_add
        str *= raw"\left("
    end
    str *= get_string(q.x; in_prog=true)
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

function get_string(x; in_prog = false)
    string(x)
end