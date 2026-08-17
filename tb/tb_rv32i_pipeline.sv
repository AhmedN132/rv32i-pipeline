`timescale 1ns/1ps
module tb_rv32i_pipeline;
    logic clk=0, rst_n=0;
    logic [31:0] imem_addr, imem_rdata;
    logic dmem_we; logic [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    logic [31:0] imem [0:255];
    logic [31:0] dmem [0:255];
    integer i;

    rv32i_pipeline dut(.*);
    always #5 clk = ~clk;
    assign imem_rdata = imem[imem_addr[9:2]];
    assign dmem_rdata = dmem[dmem_addr[9:2]];
    always_ff @(posedge clk) if (dmem_we) dmem[dmem_addr[9:2]] <= dmem_wdata;

    function automatic [31:0] addi(input int rd, rs1, imm);
      addi = {imm[11:0],rs1[4:0],3'b000,rd[4:0],7'b0010011}; endfunction
    function automatic [31:0] rtype(input int rd, rs1, rs2, input [2:0] f3, input bit sub);
      rtype = {{1'b0,sub,5'b0},rs2[4:0],rs1[4:0],f3,rd[4:0],7'b0110011}; endfunction
    function automatic [31:0] sw(input int rs2, rs1, imm);
      sw = {imm[11:5],rs2[4:0],rs1[4:0],3'b010,imm[4:0],7'b0100011}; endfunction
    function automatic [31:0] lw(input int rd, rs1, imm);
      lw = {imm[11:0],rs1[4:0],3'b010,rd[4:0],7'b0000011}; endfunction
    function automatic [31:0] branch(input int rs1,rs2,imm,input [2:0] f3);
      branch = {imm[12],imm[10:5],rs2[4:0],rs1[4:0],f3,imm[4:1],imm[11],7'b1100011}; endfunction

    task automatic init_mem;
      begin for (i=0;i<256;i=i+1) begin imem[i]=32'h00000013; dmem[i]=0; end end
    endtask

    initial begin
      init_mem();
      // Arithmetic + EX/MEM forwarding + load-use stall.
      imem[0]=addi(1,0,5);               // x1=5
      imem[1]=addi(2,0,7);               // x2=7
      imem[2]=rtype(3,1,2,3'b000,1'b0);  // x3=12
      imem[3]=rtype(6,3,1,3'b000,1'b1);  // x6=7 (SUB, forwarding)
      imem[4]=sw(3,0,0);                 // mem[0]=12
      imem[5]=lw(4,0,0);                 // x4=12
      imem[6]=addi(5,4,1);               // x5=13, load-use stall
      // Taken BEQ must flush next instruction.
      imem[7]=branch(1,1,8,3'b000);      // skip imem[8]
      imem[8]=addi(7,0,99);              // must be flushed
      imem[9]=addi(8,0,42);              // branch target

      repeat(2) @(posedge clk); rst_n<=1;
      repeat(45) @(posedge clk);

      if (dut.rf.regs[0] !== 32'd0)  $fatal(1,"x0 invariant failed");
      if (dut.rf.regs[3] !== 32'd12) $fatal(1,"ADD/forwarding failed x3=%0d",dut.rf.regs[3]);
      if (dut.rf.regs[6] !== 32'd7)  $fatal(1,"SUB forwarding failed x6=%0d",dut.rf.regs[6]);
      if (dmem[0] !== 32'd12)        $fatal(1,"SW failed mem0=%0d",dmem[0]);
      if (dut.rf.regs[4] !== 32'd12) $fatal(1,"LW failed x4=%0d",dut.rf.regs[4]);
      if (dut.rf.regs[5] !== 32'd13) $fatal(1,"load-use failed x5=%0d",dut.rf.regs[5]);
      if (dut.rf.regs[7] !== 32'd0)  $fatal(1,"branch flush failed x7=%0d",dut.rf.regs[7]);
      if (dut.rf.regs[8] !== 32'd42) $fatal(1,"branch target failed x8=%0d",dut.rf.regs[8]);
      if (imem_addr[1:0] !== 2'b00)  $fatal(1,"PC alignment failed");
      $display("PASS: RV32I pipeline arithmetic/forwarding/load-use/branch regression");
      $finish;
    end
endmodule
