struct SpinHilbertSpace <: AbstractHilbertSpace
    name::String
    spin::Rational
    function SpinHilbertSpace(name::String, spin::Rational)
        return new(name, spin)
    end
end

include("SpinOperators.jl")
include("utils.jl")


