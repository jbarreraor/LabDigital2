`include "sumador.v"
module alu(
    input  [3:0] a,
    input  [3:0] b,
    input  [1:0] op,
    output [3:0] out
);
    wire [3:0] suma, resta1, resta2;
    wire [3:0] resta;   // resta ya ordenada (mayor - menor)
    wire       a_ge_b;

    sumador4 sumalab2   (.a(a), .b(b), .cin(1'b0), .sum(suma), .cout());
    restador restalab2  (.a(a), .b(b), .resta(resta1));
    restador restalab22 (.a(b), .b(a), .resta(resta2));

    assign a_ge_b = (a >= b);
    assign resta  = a_ge_b ? resta1 : resta2;

    assign out = (op == 2'b00) ? suma  :
                 (op == 2'b01) ? resta :
                 (op == 2'b10) ? (a & b) :
                                 (a | b);   // op == 2'b11
endmodule