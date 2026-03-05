abstract type AbstractHilbertSpace end

Base.isless(a::AbstractHilbertSpace, b::AbstractHilbertSpace) = Base.hash(a) < Base.hash(b)

"""
    TotalHilbertSpace <: AbstractHilbertSpace
A special Hilbert space that represents the total hilbert space. This is used as a placeholder when the specific Hilbert space is not important or when an operator acts on the entire space. This is 
important for the identity operator, which should act on the total hilbert space.

"""
struct TotalHilbertSpace <: AbstractHilbertSpace
end


"""
    BasicHilbertSpace <: AbstractHilbertSpace

A simple implementation of a Hilbert space with a name and dimension. If dimension is 0, it represents an infinite-dimensional Hilbert space.
"""
struct BasicHilbertSpace <: AbstractHilbertSpace
    name::String
    dimension::Int
    function BasicHilbertSpace(name::String, dimension::Int)
        return new(name, dimension)
    end
end

Base.size(hs::BasicHilbertSpace) = hs.dimension == 0 ? Inf : hs.dimension
Base.show(io::IO, hs::BasicHilbertSpace) = print(io, "BasicHilbertSpace(", hs.name, ", ", hs.dimension == 0 ? "∞" : string(hs.dimension), ")")



"""
    CompositeHilbertSpace <: AbstractHilbertSpace
A Hilbert space composed of multiple Hilbert spaces combined in a composite manner. This is used for describing composite systems that are generally treated as a whole, such as spin and spatial degrees of freedom combined.
"""
struct CompositeHilbertSpace <: AbstractHilbertSpace
    spaces::Vector{AbstractHilbertSpace}
    function CompositeHilbertSpace(spaces::Vector{T}) where {T<:AbstractHilbertSpace}
        if length(spaces) == 1
            return spaces[1]
        end
        return new(spaces)
    end
end

Base.size(hs::CompositeHilbertSpace) = prod(size.(hs.spaces))
Base.show(io::IO, hs::CompositeHilbertSpace) = begin
    print(io, "CompositeHilbertSpace(")
    for (i, space) in enumerate(hs.spaces)
        print(io, space)
        if i < length(hs.spaces)
            print(io, ", ")
        end
    end
    print(io, ")")
end


"""
    TensorProductSpace <: AbstractHilbertSpace
A Hilbert space formed by the tensor product of multiple Hilbert spaces. This is used to describe systems where the overall state space is constructed from the states of individual subsystems.
"""
struct TensorProductHilbertSpace <: AbstractHilbertSpace
    spaces::Vector{AbstractHilbertSpace}
    function TensorProductHilbertSpace(spaces::Vector{T}) where {T<:AbstractHilbertSpace}
        if length(spaces) == 1
            return spaces[1]
        end
        if all(space -> space isa typeof(spaces[1]), spaces)
            return spaces[1]
        end
        return new(_reduce_TPHS(spaces))
    end
end

Base.size(hs::TensorProductHilbertSpace) = prod(size.(hs.spaces))
Base.show(io::IO, hs::TensorProductHilbertSpace) = begin
    print(io, "TensorProductHilbertSpace(")
    for (i, space) in enumerate(hs.spaces)
        print(io, space)
        if i < length(hs.spaces)
            print(io, ", ")
        end
    end
    print(io, ")")
end

function _reduce_TPHS(spaces::Vector{T}) where {T<:AbstractHilbertSpace}
    new_spaces = []
    for space in spaces
        if !(space isa TotalHilbertSpace)
            if space isa TensorProductHilbertSpace
                println(space)
                append!(new_spaces, _reduce_TPHS(space.spaces))
            else
                push!(new_spaces, space)
            end
        end
    end
    return sort(unique(new_spaces))
end


