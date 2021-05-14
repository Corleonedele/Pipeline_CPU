`include "InstructionRAM.v"
`include "MainMemory.v"
`include "ALU.v"

module CPU (CLOCK, init);
input wire CLOCK, init;

wire RESET, ENABLE;
wire [31:0]fetch_ins, fetch_data;
wire [64:0]edit_serial;

reg [31:0]regs[31:0];
reg PC = 32'h0000_0000;
reg ins_address = 32'h0000_0000;
reg data_address = 32'h0000_0000;
reg[5:0] opcode, funct, shamt;

reg [15:0]imm;

reg[31:0] ALU_regA;
reg[31:0] ALU_regB;
reg[31:0] ALU_result;


reg [63:0] IF_ID;
reg [129:0] ID_EX;
reg [53:0] EX_MEM;
reg [78:0] MEM_WB;


reg overflow;

reg RegWrite;
reg MemtoReg;
reg MemWrite;
reg RegDst;
reg ALUSrc;

reg Branch;
reg ALU_control;

reg PCSrs;

reg ALUGate;
reg MemRead;


reg PC_con = 1'b1;

reg [31:0]ins;





// Instruction Fetch From Instruction Memory
always @(posedge CLOCK)
begin   
    ins = fetch_ins; 
    if (PC_con == 1'b1)
    begin
        opcode = ins[31:26];
        funct = ins[5:0];

        case(opcode)
            6'b000010: // srl
            begin
                PC = PC + 4 + 4 * ins[25:0];
            end
            6'b000011: // sra
            begin
                regs[31] = PC + 4;
                PC = PC + 4 + 4 * ins[25:0];
            end
            6'b000100: // beq
            begin
                if (ins[25:21] == ins[20:16])
                    PC = PC + 4 + 4 * ins[15:0];
            end
            6'b000101: // bne
            begin
                if (ins[25:21] != ins[20:16])
                    PC = PC + 4 + 4 * ins[15:0];
            end
            6'b000000:
                case(funct)
                    6'b000000: // sll
                    begin
                        
                    end
                    6'b000100: // sllv
                    begin
                        
                    end
                    6'b000010: // srlv
                    begin
                        
                    end
                    6'b000110: //srav
                    begin
                        
                    end
                    6'b101010: //slt
                    begin
                        
                    end
                endcase
        endcase
    PC = PC + 4;
    IF_ID[31:0] = ins;
    IF_ID[63:32] = PC;  
    
    end
    else    
    begin
        PC = PC - 4 - 4;
        IF_ID[31:0] = ins;
        IF_ID[63:32] = PC;
    end

end




// Instruction Decoding and Register Read
always @(posedge CLOCK) 
begin
    opcode = IF_ID[31:26];
    funct = IF_ID[5:0];

    if (opcode == 6'b100011 || opcode == 6'b101011 || opcode == 6'b001000 || opcode == 6'b001001)
        ID_EX[31:0] = {{16{IF_ID[15]}}, IF_ID[15:0]};
    else
        ID_EX[31:0] = {16'b0, IF_ID[15:0]};



    ID_EX[107:102] = opcode;
    ID_EX[101:96] = funct;

    ID_EX[114] = RegDst;
    ID_EX[113] = RegWrite;
    ID_EX[112] = ALUGate;
    ID_EX[111] = ALUSrc;
    ID_EX[110] = MemRead;
    ID_EX[109] = MemWrite;
    ID_EX[108] = MemtoReg;

    ID_EX[129:125] = IF_ID[25:21];
    ID_EX[124:120] = IF_ID[20:16];
    ID_EX[119:115] = IF_ID[15:11];

    // ID_EX[63:32] = IF_ID[31:0];
end





//Execute Operation or Calculate Address
always @(posedge CLOCK) 
begin
    overflow = 1'b0;
    opcode = ID_EX[63:58];
    funct = ID_EX[37:32];
    // imm = ID_EX[47:32];
    // shamt = ID_EX[42:38];


    if (ID_EX[112] == 1'b1)
    begin
        ALU_regA = regs[ID_EX[129:115]];
        if (ID_EX[111] == 1'b1)
            ALU_regB = ID_EX[31:0];
        else 
            ALU_regB = regs[ID_EX[124:120]];
    end

    // Execiton
    case(opcode)
        6'b000000: begin
            case(funct)
                //add
                6'b100000: begin              
                    ALU_result = $signed(ALU_regA) + $signed(ALU_regB);
                end

                //addu 
                6'b100001: begin
                    ALU_result = ALU_regA + ALU_regB;
                end

                //sub
                6'b100010: begin
                    ALU_result = $signed(ALU_regA) - $signed(ALU_regB);
                end

                //subu
                6'b100011: begin 
                    ALU_result = $unsigned(ALU_regA) - $unsigned(ALU_regB);
                end

                //and
                6'b100100: begin
                    ALU_result = ALU_regA & ALU_regB;
                end

                //nor
                6'b100111: begin
                    ALU_result = ~(ALU_regA | ALU_regB);
                end

                //or
                6'b100101: begin
                    ALU_result = ALU_regA | ALU_regB;
                end

                //xor
                6'b100110: begin
                    ALU_result = ALU_regA ^ ALU_regB;
                end

                //slt
                6'b101010: begin

                end

                //sltu
                6'b101011: begin

                end

                //sll
                6'b000000: begin
                    ALU_result = ALU_regB << shamt;
                end

                //sllv
                6'b000100: begin
                    ALU_result = ALU_regB << ALU_regA;
                end

                //srl
                6'b000010: begin
                    ALU_result = $unsigned(ALU_regB) >> shamt;
                end

                //srlv
                6'b000110: begin
                    ALU_result = $unsigned(ALU_regB) >> $unsigned(ALU_regA);
                end

                //sra
                6'b000011: begin
                    ALU_result = $signed(ALU_regB) >>> shamt;
                end

                //srav
                6'b000111: begin
                    ALU_result = $signed(ALU_regB) >>> $unsigned(ALU_regA);
                end
            endcase
        end

        //addi
        6'b001000: begin
            ALU_result = $signed(ALU_regA) + $signed(imm);
        end
        
        //addiu
        6'b001001: begin
            ALU_result = $unsigned(ALU_regA) + $unsigned(imm);
        end

        //andi
        6'b001100: begin
            ALU_result = ALU_regA & imm;
        end

        //ori
        6'b001101: begin
            ALU_result = ALU_regA | imm;
        end

        //xori
        6'b001110: begin
            ALU_result = ALU_regA ^ imm;
        end

        //beq
        6'b000100: begin

        end

        //bne
        6'b000101: begin

        end

        //slti
        6'b001010: begin

        end

        //sltiu
        6'b001011: begin
            ALU_result = ALU_regA - imm;
        end

        //lw
        6'b100011: begin
            ALU_result = ALU_regA + $signed(imm);
        end

        //sw
        6'b101011: begin
            ALU_result = ALU_regA + $signed(imm) ;
        end
    endcase

    EX_MEM[31:0] = ALU_result;
    //store control signals to EX_MEM
    EX_MEM[36] = ID_EX[114];
    EX_MEM[35] = ID_EX[113];
    EX_MEM[34] = ID_EX[110];
    EX_MEM[33] = ID_EX[109];
    EX_MEM[32] = ID_EX[108];
    EX_MEM[53] = ID_EX[112];
    EX_MEM[52] = ID_EX[111];

    EX_MEM[51:47] = ID_EX[129:125];
    EX_MEM[46:42] = ID_EX[124:120];
    EX_MEM[41:37] = ID_EX[119:115];
end






// Access Data Memory Operand
always @(posedge CLOCK) 
begin
    

end





// Write Result Back To Register
always @(posedge CLOCK) 
begin
    
end

endmodule