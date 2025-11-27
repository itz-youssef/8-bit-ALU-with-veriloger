module not_forALU (output [7:0] Y, input [7:0] A);
    assign Y = ~A;
endmodule

module and_forALU (output [7:0] Y, input [7:0] A, B);
    assign Y = A & B;
endmodule

module or_forALU (output [7:0] Y, input [7:0] A, B);
    assign Y = A | B;
endmodule

module nand_forALU (output [7:0] Y, input [7:0] A, B);
    assign Y = ~(A & B);
endmodule

module shl_forALU (output [7:0] Y, input [7:0] B);
    assign Y = {B[6:0], 1'b0};
endmodule

module shr_forALU (output [7:0] Y, input [7:0] B);
    assign Y = {B[7], B[7:1]};
endmodule

module rotr_forALU (output [7:0] Y, input [7:0] A);
    assign Y = {A[0], A[7:1]};
endmodule

module rotl_forALU (output [7:0] Y, input [7:0] A);
    assign Y = {A[6:0], A[7]};
endmodule

module eq_forALU (output [7:0] Y, input [7:0] A, B);
    wire eq = ~|(A ^ B);
    assign Y = {7'b0000000, eq};
endmodule

module full_adder (
    output sum, carry_out,
    input a, b, carry_in
);
    assign {carry_out, sum} = a + b + carry_in;
endmodule

module adder_forALU #(parameter WIDTH = 8)
(
    output [WIDTH-1:0] Sum,
    output Overflow,
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input Cin
);

    wire [WIDTH:0] C;   // carries
    assign C[0] = Cin;

    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: adder_loop
            full_adder FA (
                .sum(Sum[i]),
                .carry_out(C[i+1]),
                .a(A[i]),
                .b(B[i]),
                .carry_in(C[i])
            );
        end
    endgenerate

    assign Overflow = C[WIDTH] ^ C[WIDTH-1];

endmodule

module mux_forALU (
    output [7:0] Y,
    input [3:0] S,
    input [7:0] I0, I1, I2, I3, I4, I5, I6, I7,
    input [7:0] I8, I9, I10, I11, I12, I13, I14, I15
);
    assign Y =
        (S == 4'b0000) ? I0  :
        (S == 4'b0001) ? I1  :
        (S == 4'b0010) ? I2  :
        (S == 4'b0011) ? I3  :
        (S == 4'b0100) ? I4  :
        (S == 4'b0101) ? I5  :
        (S == 4'b0110) ? I6  :
        (S == 4'b0111) ? I7  :
        (S == 4'b1000) ? I8  :
        (S == 4'b1001) ? I9  :
        (S == 4'b1010) ? I10 :
        (S == 4'b1011) ? I11 :
        (S == 4'b1100) ? I12 :
        (S == 4'b1101) ? I13 :
        (S == 4'b1110) ? I14 :
                        I15;
endmodule

module ALU_8 (
    output [7:0] Result,
    output Zero,
    output Negative,
    output Overflow,
    input [7:0] A, B,
    input [3:0] AluOp
);

    wire [7:0] Adder_A_in;
    wire [7:0] Adder_B_in;
    wire Adder_Cin;
    wire [7:0] Adder_Sum;
    wire Adder_Overflow_raw;

    wire [7:0] not_A_out;
    wire [7:0] and_out;
    wire [7:0] or_out;
    wire [7:0] nand_out;
    wire [7:0] shl_out;
    wire [7:0] shr_out;
    wire [7:0] rotl_out;
    wire [7:0] rotr_out;
    wire [7:0] eq_out;

    wire [7:0] Mux_Output;

    assign Adder_Cin = (AluOp == 4'b0001) | (AluOp == 4'b0010);

    assign Adder_A_in = (AluOp == 4'b0001) ? B : A;

    assign Adder_B_in = 
        (AluOp[1:0] == 2'b00) ? B :          
        (AluOp[1:0] == 2'b01) ? ~A :         
        (AluOp[1:0] == 2'b10) ? 8'h00 :      
        8'h00; 

    adder_forALU ADDER (
        .Sum(Adder_Sum),
        .Overflow(Adder_Overflow_raw),
        .A(Adder_A_in),
        .B(Adder_B_in),
        .Cin(Adder_Cin)
    );

    not_forALU NOT_OP (.Y(not_A_out), .A(A));
    and_forALU AND_OP (.Y(and_out), .A(A), .B(B));
    or_forALU OR_OP (.Y(or_out), .A(A), .B(B));
    nand_forALU NAND_OP (.Y(nand_out), .A(A), .B(B));
    shl_forALU SHL_OP (.Y(shl_out), .B(B)); 
    shr_forALU SHR_OP (.Y(shr_out), .B(B)); 
    rotr_forALU ROTR_OP (.Y(rotr_out), .A(A)); 
    rotl_forALU ROTL_OP (.Y(rotl_out), .A(A)); 
    eq_forALU EQ_OP (.Y(eq_out), .A(A), .B(B));

    mux_forALU MUX (
        .Y(Mux_Output), 
        .S(AluOp),
        .I0(Adder_Sum),        
        .I1(Adder_Sum),        
        .I2(Adder_Sum),        
        .I3(8'h00),             
        .I4(8'h00),             
        .I5(eq_out),           
        .I6(shl_out),          
        .I7(shr_out),          
        .I8(not_A_out),        
        .I9(and_out),          
        .I10(or_out),          
        .I11(nand_out),        
        .I12(rotl_out),        
        .I13(rotr_out),        
        .I14(8'h00),            
        .I15(8'h00)             
    );

    assign Result = Mux_Output;
    assign Zero = (Result == 8'h00);
    assign Negative = Result[7];
    assign Overflow = (AluOp == 4'b0000 || AluOp == 4'b0001) ? Adder_Overflow_raw : 1'b0;

endmodule 

module ALU_8_test;

    reg [7:0] A, B;
    reg [3:0] AluOp;

    wire [7:0] Result;
    wire Zero, Negative, Overflow;

    
    wire signed [7:0] A_s, B_s, R_s;
    wire Zero_s, Negative_s, Overflow_s;

    
    assign A_s = A;
    assign B_s = B;
    assign R_s = Result;
    assign Zero_s = Zero;
    assign Negative_s = Negative;
    assign Overflow_s = Overflow;

    ALU_8 DUT (
        .Result(Result),
        .Zero(Zero),
        .Negative(Negative),
        .Overflow(Overflow),
        .A(A),
        .B(B),
        .AluOp(AluOp)
    );

    initial begin
        $dumpfile("ALU_8.vcd");
        $dumpvars(0, ALU_8_test);
    end

    initial begin
        A = 0;
        B = 0;
        AluOp = 4'b0000;
        #1;

        
        $monitor("A=%h (%d), B=%h (%d), AluOp=%b, Result=%h (%d), Zero=%b, Negative=%b, Overflow=%b",
                 A_s, A_s, B_s, B_s, AluOp, R_s, R_s, Zero_s, Negative_s, Overflow_s);

        A = 8'd10; B = 8'd5;    #10 AluOp = 4'b0000; 
                                #10 AluOp = 4'b0001; 
                                #10 AluOp = 4'b0010; 

        A = 8'd127; B = 8'd1;   #10 AluOp = 4'b0000; 

        A = 8'd1; B = 8'h80;    #10 AluOp = 4'b0001; 

        A = 8'd42; B = 8'd42;   #10 AluOp = 4'b0101; 
        A = 8'd42; B = 8'd43;   #10 AluOp = 4'b0101; 

        A = 8'hAA; B = 8'h55;   #10 AluOp = 4'b1000; 
                                #10 AluOp = 4'b1001; 
                                #10 AluOp = 4'b1010; 

        A = 8'hC3; B = 8'h60;   #10 AluOp = 4'b0110; 
                                #10 AluOp = 4'b0111; 

                                #10 AluOp = 4'b1100; 
                                #10 AluOp = 4'b1101; 

        #10 $finish;
    end

endmodule
