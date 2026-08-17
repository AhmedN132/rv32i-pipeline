"""Tiny RV32I encoder for directed verification programs."""
def addi(rd, rs1, imm): return ((imm & 0xfff)<<20)|(rs1<<15)|(0<<12)|(rd<<7)|0x13
def add(rd, rs1, rs2): return (rs2<<20)|(rs1<<15)|(0<<12)|(rd<<7)|0x33
def sub(rd, rs1, rs2): return (0x20<<25)|(rs2<<20)|(rs1<<15)|(0<<12)|(rd<<7)|0x33
def lw(rd, rs1, imm): return ((imm & 0xfff)<<20)|(rs1<<15)|(2<<12)|(rd<<7)|0x03
def sw(rs2, rs1, imm): return (((imm>>5)&0x7f)<<25)|(rs2<<20)|(rs1<<15)|(2<<12)|((imm&0x1f)<<7)|0x23
if __name__ == '__main__':
    p=[addi(1,0,5), addi(2,0,7), add(3,1,2), sw(3,0,0), lw(4,0,0), addi(5,4,1)]
    print('\n'.join(f'{x:08x}' for x in p))
