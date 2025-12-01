# Symbolic Quantum Mechanics in Julia!

The Goal:
- To provide a framework for symbolic quantum mechanics calculations in Julia capable of doing problems ranging from simple quantum algebra manipulations to many-body lattice hamiltonians and eventually quantum field theories. 
- Currently this packages focuses on operators, perturbation theory via Schrieffer-Wolff transformations, and symbolic representations of Hamiltonians.
  - Eventually, if this packages gains full QFT support, automatic generation of Feynman diagrams and symbolic evaluation of integrals may be possible.
- A secondary goal of this package is to provide a translatable language for defining quantum systems that can be used to generate code for numerical simulations in other Julia packages (e.g. QuantumToolbox.jl, ITensors.jl, etc...).
  - (This package is very much motivated by my work in superconducting circuit simulations and will hopefully serve as the foundation for the next version of SuperconductingCircuits.jl).
  - Eventually, I would also like to add supports for states! 


## Status
Very much in development!

## Contributing
Contributions and collaborations are very welcome! Feel free to start a discussion, open issues, PRs and reach out to me via email (gavin.rockwood@gmail.com).

[![Build Status](https://github.com/Gavin-Rockwood/SymbolicQuantumMechanics.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/Gavin-Rockwood/SymbolicQuantumMechanics.jl/actions/workflows/CI.yml?query=branch%3Amain)
