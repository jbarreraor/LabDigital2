`include "alu.v"
`include "antir.v"

module lab2(
    input  clk,
    input  guardarA,        // BTN0
    input  guardarB,        // BTN1
    input  opBit0,          // BTN2
    input  opBit1,          // BTN3
    input  [3:0] X,
    output [3:0] out,
    output reg [2:0] rgb
);
    reg [3:0] a  = 4'b0000;
    reg [3:0] b  = 4'b0000;
    reg [1:0] op = 2'b00;

    wire pA, pB, pOp0, pOp1;

    antirebote dbA   (.clk(clk), .btn(guardarA), .pulso(pA));
    antirebote dbB   (.clk(clk), .btn(guardarB), .pulso(pB));
    antirebote dbOp0 (.clk(clk), .btn(opBit0),   .pulso(pOp0));
    antirebote dbOp1 (.clk(clk), .btn(opBit1),   .pulso(pOp1));

    always @(posedge clk) begin
        if (pA)   a     <= X;
        if (pB)   b     <= X;
        if (pOp0) op[0] <= X[0];
        if (pOp1) op[1] <= X[1];
    end

    alu alulab2 (.a(a), .b(b), .op(op), .out(out));

    always @(*) begin
        case (op)
            2'b00:   rgb = 3'b010;  // suma: verde
            2'b01:   rgb = 3'b100;  // resta: rojo
            2'b10:   rgb = 3'b101;  // AND: morado
            2'b11:   rgb = 3'b110;  // OR: amarillo
            default: rgb = 3'b000;
        endcase
    end
endmodule