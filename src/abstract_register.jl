export AbstractRegister

"""
    AbstractRegister{B, T}

Abstract type for quantum registers. `B` is the batch size, `T` is the
data type.
"""
abstract type AbstractRegister{B, T} end

# properties
"""
    nactive(register) -> Int

Returns the number of active qubits.

note!!!

    Operators always apply on active qubits.
"""
@interface nactive(::AbstractRegister)

"""
    nqubits(register) -> Int

Returns the (total) number of qubits. See [`nactive`](@ref), [`nremain`](@ref)
for more details.
"""
@interface nqubits(::AbstractRegister)

"""
    nremain(register) -> Int

Returns the number of non-active qubits.
"""
@interface nremain(r::AbstractRegister) = nqubits(r) - nactive(r)

"""
    nbatch(register) -> Int

Returns the number of batches.
"""
@interface nbatch(r::AbstractRegister{B}) where B = B

"""
    datatype(register) -> Int

Returns the numerical data type used by register.

note!!!

    `datatype` is not the same with `eltype`, since `AbstractRegister` family
    is not exactly the same with `AbstractArray`, it is an iterator of several
    registers.
"""
@interface datatype(r::AbstractRegister{B, T}) where {B, T} = T

"""
    viewbatch(register, i::Int) -> AbstractRegister{1}

Returns a view of the i-th slice on batch dimension.
"""
@interface viewbatch(::AbstractRegister, ::Int)

# TODO: move this method to `DefaultRegister`

"""
    state(register) -> AbstractMatrix

Returns the raw state of register. This always returns a matrix which is a batch
of quantum states.
"""
@interface state(::AbstractRegister)

"""
    addbit!(register, n::Int) -> register
    addbit!(n::Int) -> Function

addbit the register by n bits in state |0>.
i.e. |psi> -> |000> ⊗ |psi>, addbit bits have higher indices.
If only an integer is provided, then perform lazy evaluation.
"""
@interface addbit!(::AbstractRegister)

"""
    focus!(register, locs::Int...) -> register
    focus!(locs::Int...) -> f(register) -> register

Focus the wires on specified location.
"""
@interface focus!(::AbstractRegister, locs; nbit)

"""
    relax!(register[, locs]; nbit::Int=nqubits(register)) -> register
    relax!(locs; nbit::Int=nqubits(register)) -> f(register) -> register

Inverse transformation of [`focus!`](@ref), where `nbit` is the number
 of active bits for target register.
"""
@interface relax!(::AbstractRegister, locs; nbit)

## Measurement

"""
    measure(register[, ntimes=1]) -> Vector{Int}

Return measurement results of current active qubits (regarding to active qubits,
see [`focus!`](@ref) and [`relax!`](@ref)).
"""
@interface measure(::AbstractRegister, ntimes::Int=1)

"""
    select!(dest::AbstractRegister, src::AbstractRegister, bits::Integer...) -> AbstractRegister
    select!(register::AbstractRegister, bits::Integer...) -> register
    select!(b::Integer) -> f(register)

select a subspace of given quantum state based on input eigen state `bits`.

## Example

`select!(reg, 0b110)` will select the subspace with (focused) configuration `110`.
After selection, the focused qubit space is 0, so you may want call `relax!` manually.
"""
@interface select!(dest::AbstractRegister, bits...)

"""
    select(register, bits...) -> AbstractRegister

Non-inplace version of [`select!`](@ref).
"""
@interface select(register::AbstractRegister, bits...) = select!(copy(register), bits...)

@interface select!(::AbstractRegister, bits)

"""
    join(::AbstractRegister...) -> register

Merge several registers as one register via tensor product.
"""
@interface Base.join(::AbstractRegister...)

"""
    repeat(r::AbstractRegister, n::Int) -> register

Repeat register `r` for `n` times on batch dimension.

### Example
"""
@interface Base.repeat(::AbstractRegister, n::Int)

"""
    basis(register) -> UnitRange

Returns an `UnitRange` of the all the bits in the Hilbert space of given register.
"""
@interface basis(::AbstractRegister)

"""
    density_matrix(register)

Returns the density matrix of current active qubits.
"""
@interface density_matrix(::AbstractRegister)

"""
    ρ(register)

Returns the density matrix of current active qubits. This is the same as
[`density_matrix`](@ref).
"""
@interface ρ(x) = density_matrix(x)

# fallback printing
function Base.show(io::IO, reg::AbstractRegister)
    summary(io, reg)
    print(io, "\n    active qubits: ", nactive(reg), "/", nqubits(reg))
end
