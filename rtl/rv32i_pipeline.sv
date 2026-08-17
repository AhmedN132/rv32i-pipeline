module rv32i_pipeline (
    input  logic        clk,
    input  logic        rst_n,
    output logic [31:0] imem_addr,
    input  logic [31:0] imem_rdata,
    output logic        dmem_we,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata,
    input  logic [31:0] dmem_rdata
);
    localparam ALU_ADD=4'd0, ALU_SUB=4'd1, ALU_AND=4'd2, ALU_OR=4'd3,
               ALU_XOR=4'd4, ALU_SLT=4'd5;

    logic [31:0] pc_f;
    logic [31:0] pc_d, instr_d;
    logic valid_d;

    logic [4:0] rs1_d, rs2_d, rd_d;
    logic [6:0] opcode_d, funct7_d;
    logic [2:0] funct3_d;
    logic [31:0] imm_d, rv1_d, rv2_d;
    logic regwrite_d, memread_d, memwrite_d, alusrc_d, branch_d, jump_d;
    logic [3:0] aluop_d;

    logic valid_e, regwrite_e, memread_e, memwrite_e, alusrc_e, branch_e, jump_e;
    logic [31:0] pc_e, rv1_e, rv2_e, imm_e;
    logic [4:0] rs1_e, rs2_e, rd_e;
    logic [2:0] funct3_e;
    logic [3:0] aluop_e;

    logic valid_m, regwrite_m, memread_m, memwrite_m;
    logic [31:0] alu_m, store_m;
    logic [4:0] rd_m;

    logic valid_w, regwrite_w, memread_w;
    logic [31:0] alu_w, mem_w;
    logic [4:0] rd_w;
    logic [31:0] wb_data;

    logic [31:0] fwd_a, fwd_b, alu_b, alu_y;
    logic branch_taken_e, redirect_e;
    logic [31:0] redirect_pc_e;
    logic stall_load_use;

    assign imem_addr = pc_f;
    assign rs1_d = instr_d[19:15];
    assign rs2_d = instr_d[24:20];
    assign rd_d = instr_d[11:7];
    assign opcode_d = instr_d[6:0];
    assign funct3_d = instr_d[14:12];
    assign funct7_d = instr_d[31:25];

    regfile rf(.clk(clk), .we(valid_w && regwrite_w), .rs1(rs1_d), .rs2(rs2_d),
               .rd(rd_w), .wd(wb_data), .rv1(rv1_d), .rv2(rv2_d));
    assign wb_data = memread_w ? mem_w : alu_w;

    always_comb begin
        regwrite_d=0; memread_d=0; memwrite_d=0; alusrc_d=0; branch_d=0; jump_d=0;
        aluop_d=ALU_ADD; imm_d=32'b0;
        case (opcode_d)
            7'b0110011: begin // R-type
                regwrite_d=1;
                case ({funct7_d[5],funct3_d})
                    4'b1000: aluop_d=ALU_SUB;
                    4'b0111: aluop_d=ALU_AND;
                    4'b0110: aluop_d=ALU_OR;
                    4'b0100: aluop_d=ALU_XOR;
                    4'b0010: aluop_d=ALU_SLT;
                    default: aluop_d=ALU_ADD;
                endcase
            end
            7'b0010011: begin // ADDI only
                regwrite_d=1; alusrc_d=1; aluop_d=ALU_ADD;
                imm_d={{20{instr_d[31]}},instr_d[31:20]};
            end
            7'b0000011: begin // LW
                regwrite_d=1; memread_d=1; alusrc_d=1; aluop_d=ALU_ADD;
                imm_d={{20{instr_d[31]}},instr_d[31:20]};
            end
            7'b0100011: begin // SW
                memwrite_d=1; alusrc_d=1; aluop_d=ALU_ADD;
                imm_d={{20{instr_d[31]}},instr_d[31:25],instr_d[11:7]};
            end
            7'b1100011: begin // BEQ/BNE
                branch_d=1; aluop_d=ALU_SUB;
                imm_d={{19{instr_d[31]}},instr_d[31],instr_d[7],instr_d[30:25],instr_d[11:8],1'b0};
            end
            7'b1101111: begin // JAL
                regwrite_d=1; jump_d=1;
                imm_d={{11{instr_d[31]}},instr_d[31],instr_d[19:12],instr_d[20],instr_d[30:21],1'b0};
            end
            default: ;
        endcase
    end

    assign stall_load_use = valid_e && memread_e && rd_e != 0 && valid_d &&
                            ((rd_e == rs1_d) || ((rd_e == rs2_d) && opcode_d != 7'b0010011));

    always_comb begin
        fwd_a = rv1_e; fwd_b = rv2_e;
        if (valid_m && regwrite_m && !memread_m && rd_m != 0 && rd_m == rs1_e) fwd_a = alu_m;
        else if (valid_w && regwrite_w && rd_w != 0 && rd_w == rs1_e) fwd_a = wb_data;
        if (valid_m && regwrite_m && !memread_m && rd_m != 0 && rd_m == rs2_e) fwd_b = alu_m;
        else if (valid_w && regwrite_w && rd_w != 0 && rd_w == rs2_e) fwd_b = wb_data;
    end

    assign alu_b = alusrc_e ? imm_e : fwd_b;
    alu u_alu(.a(fwd_a), .b(alu_b), .op(aluop_e), .y(alu_y));

    always_comb begin
        branch_taken_e = 1'b0;
        if (branch_e) begin
            case (funct3_e)
                3'b000: branch_taken_e = (fwd_a == fwd_b); // BEQ
                3'b001: branch_taken_e = (fwd_a != fwd_b); // BNE
                default: branch_taken_e = 1'b0;
            endcase
        end
    end
    assign redirect_e = valid_e && (jump_e || (branch_e && branch_taken_e));
    assign redirect_pc_e = pc_e + imm_e;

    assign dmem_we = valid_m && memwrite_m;
    assign dmem_addr = alu_m;
    assign dmem_wdata = store_m;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_f <= 0; valid_d<=0; valid_e<=0; valid_m<=0; valid_w<=0;
        end else begin
            // WB
            valid_w<=valid_m; regwrite_w<=regwrite_m; memread_w<=memread_m;
            alu_w<=alu_m; mem_w<=dmem_rdata; rd_w<=rd_m;

            // MEM
            valid_m<=valid_e; regwrite_m<=regwrite_e; memread_m<=memread_e; memwrite_m<=memwrite_e;
            alu_m<= jump_e ? (pc_e+32'd4) : alu_y; store_m<=fwd_b; rd_m<=rd_e;

            if (redirect_e) begin
                pc_f<=redirect_pc_e; valid_d<=0; valid_e<=0;
            end else if (stall_load_use) begin
                // Hold IF/ID; inject bubble into EX
                valid_e<=0;
            end else begin
                // ID -> EX
                valid_e<=valid_d; pc_e<=pc_d; rv1_e<=rv1_d; rv2_e<=rv2_d; imm_e<=imm_d;
                rs1_e<=rs1_d; rs2_e<=rs2_d; rd_e<=rd_d; funct3_e<=funct3_d;
                regwrite_e<=regwrite_d; memread_e<=memread_d; memwrite_e<=memwrite_d;
                alusrc_e<=alusrc_d; branch_e<=branch_d; jump_e<=jump_d; aluop_e<=aluop_d;
                // IF -> ID
                valid_d<=1; pc_d<=pc_f; instr_d<=imem_rdata; pc_f<=pc_f+32'd4;
            end
        end
    end

endmodule
