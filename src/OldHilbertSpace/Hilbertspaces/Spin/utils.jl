# function available_operators(hilbertspace::SingleParticleHilbertSpace)
#     return [PositionOperator, MomentumOperator, LadderOperator]
# end

# function px_to_ladder(x::QExpression, hilbertspace::SingleParticleHilbertSpace, m, ω)
    
# end

# function ladder_to_px(x::QExpression, hilbertspace::SingleParticleHilbertSpace, m, ω)
   
# end


# for T in (:PositionOperator, :MomentumOperator, :LadderOperator)
#     @eval function Base.string(x::$T; in_prog=false)
#         str = "$(x.name)"
#         if in_prog
#             return str
#         else
#             return raw"$" * str * raw"$"
#         end
#     end
# end
