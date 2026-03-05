struct SingleParticleHilbertSpace <: AbstractHilbertSpace
    name::String
    function SingleParticleHilbertSpace(name::String)
        return new(name)
    end
end

include("SingleParticleOperators.jl")
include("utils.jl")


