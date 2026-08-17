RTL=rtl/regfile.sv rtl/alu.sv rtl/rv32i_pipeline.sv
TB=tb/tb_rv32i_pipeline.sv
.PHONY: test clean
test:
	iverilog -g2012 -o simv $(RTL) $(TB)
	vvp simv
clean:
	rm -f simv *.vcd
