const MINIMAL_HEAD = "\\documentclass{minimal}\n\\usepackage[matrix,frame,arrow]{xypic}\n\\usepackage[braket]{qcircuit}\n\\begin{document}\n\\["
const MINIMAL_FOOT = "\n\\]\n\\end{document}"

struct CircuitTeX
	reg::Vector{String}
	idx::Vector{Int}
	col_spacing::Real
	row_spacing::Real
	function CircuitTeX(blk::AbstractBlock, cs::Real, rs::Real)
		@assert cs ≥ 0.0 "Column spacing needs to be positive."
		@assert rs ≥ 0.0 "Row spacing needs to be positive."
		n = nqudits(blk)
		reg = ["" for i in 1:n]
		return new(reg,Int[],cs,rs)
	end
end

function header(c::CircuitTeX) :: String
	return "\\Qcircuit @C=$(c.col_spacing)em @R=$(c.row_spacing)em  {"
end

function polish!(c::CircuitTeX)
	for i in eachindex(c.reg)
		if i ∉ c.idx
			c.reg[i] *= "\\qw"
		end
	end
	newcolumn!(c)
	map!(x -> x*"\\qw", c.reg, c.reg)
	map!(x -> "& \\qw & "*x, c.reg, c.reg)
	for i in 1:length(c.reg)-1
		c.reg[i] *= " \\\\"
	end
end

footer(c::CircuitTeX) :: String = "}"

# make a new column by inserting & in all registers/lines
newcolumn!(c::CircuitTeX) = map!(x -> x*" & ",c.reg, c.reg)

function draw!(c::CircuitTeX, blk::AbstractBlock, address, controls)
	return 
end
# Special primitive gates
function draw!(c::CircuitTeX, ::I2Gate, address, controls)
    return
end
function draw!(c::CircuitTeX, ::IdentityGate, address, controls)
    return
end


function draw!(c::CircuitTeX, blk::ChainBlock, address, controls)
    for block in subblocks(blk)
        draw!(c, block, address, controls)
    end
end

addblock!(c::CircuitTeX, blk::AbstractBlock) = draw!(c, blk, collect(1:nqudits(blk)), [])
addblock!(c::CircuitTeX, blk::Function) = addblock!(c, blk(length(c.reg)))

"""
    texcircuit(circuit; col_spacing=1, row_spacing=0.7, filename=nothing)

Generate a LaTeX QCircuit from a `Yao` quantum circuit.

### Keyword Arguments
* `col_spacing` is the circuit column width.
* `row_spacing` is the circuit row width.
* `filename` can be `"*.tex"` or nothing (not saving to a file).
* `minimal_wrap` wraps the generated QCircuit object in a `minimal` class document.

### Styles
To change the gates styles like colors and lines, please modify the constants in submodule `CircuitStyles`.
They are defined as:

* CircuitStyles.unit = Ref(60)                      # number of points in a unit
* CircuitStyles.r = Ref(0.2)                        # size of nodes
* CircuitStyles.lw = Ref(1.0)                       # line width
* CircuitStyles.textsize = Ref(16.0)                # text size
* CircuitStyles.paramtextsize = Ref(10.0)           # text size (longer texts)
* CircuitStyles.fontfamily = Ref("monospace")       # font family
* CircuitStyles.linecolor = Ref("#000000")          # line color
* CircuitStyles.gate_bgcolor = Ref("transparent")   # gate background color
* CircuitStyles.textcolor = Ref("#000000")          # text color
"""
function texcircuit(blk::AbstractBlock; col_spacing=1.0, row_spacing=0.7, filename=nothing, minimal_wrap=false)
	c = CircuitTeX(blk,col_spacing,row_spacing)
	h = header(c)
	addblock!(c,blk)
	polish!(c)
	t = footer(c)
	tex = join([h,c.reg...,t],"\n")
	if minimal_wrap
		tex = join([MINIMAL_HEAD, tex, MINIMAL_FOOT])
	end
	if !(filename === nothing)
		@assert filename[end-3:end] == ".tex" "filename argument should end in .tex."
		io = open(filename, "w")
		write(io, tex)
		close(io)
		return
	else
    	return tex
	end
end

"""An alias of `texcircuit`"""
latexify(;kwargs...) = x->latexify(x;kwargs...)
latexify(blk::AbstractBlock; kwargs...) = texcircuit(blk; kwargs...)
