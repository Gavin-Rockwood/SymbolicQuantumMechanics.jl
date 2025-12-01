struct Identity <: QSym
    at 
    name 
    metadata 
    dag::Bool
    Identity() = new(nothing, :I, Dict{Symbol,Any}(), false)
end