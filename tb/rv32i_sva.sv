// Optional concurrent assertions for simulators with full SVA support.
module rv32i_sva(input logic clk, rst_n, input logic [31:0] pc, x0);
  property p_x0_zero; @(posedge clk) disable iff(!rst_n) x0 == 32'b0; endproperty
  assert property(p_x0_zero);
  property p_aligned_pc; @(posedge clk) disable iff(!rst_n) pc[1:0] == 2'b00; endproperty
  assert property(p_aligned_pc);
endmodule
