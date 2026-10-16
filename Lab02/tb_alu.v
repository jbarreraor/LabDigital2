`timescale 1ns/1ps
`include "alu.v"

module tb_alu;
    reg  [3:0] a, b;
    reg  [1:0] op;
    wire [3:0] out;

    alu uut (.a(a), .b(b), .op(op), .out(out));

    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);

        // ---------- SUMA (00) ----------
        op = 2'b00;
        a = 4'd3;  b = 4'd4;  #10;   // normal: 7
        a = 4'd9;  b = 4'd8;  #10;   // desborda: 17 -> 1
        a = 4'd15; b = 4'd1;  #10;   // desborda: 16 -> 0
        a = 4'd15; b = 4'd15; #10;   // desborda: 30 -> 14
        a = 4'd0;  b = 4'd0;  #10;   // ceros

        // ---------- RESTA (01) ----------
        op = 2'b01;
        a = 4'd9;  b = 4'd4;  #10;   // a > b: 5
        a = 4'd4;  b = 4'd9;  #10;   // a < b: 5
        a = 4'd7;  b = 4'd7;  #10;   // a = b: 0
        a = 4'd15; b = 4'd0;  #10;   // 15
        a = 4'd0;  b = 4'd15; #10;   // a < b: 15

        // ---------- AND (10) ----------
        op = 2'b10;
        a = 4'b1100; b = 4'b1010; #10;   // 1000
        a = 4'b1111; b = 4'b0101; #10;   // 0101
        a = 4'b1010; b = 4'b0101; #10;   // 0000
        a = 4'b1111; b = 4'b1111; #10;   // 1111

        // ---------- OR (11) ----------
        op = 2'b11;
        a = 4'b1100; b = 4'b1010; #10;   // 1110
        a = 4'b0000; b = 4'b0101; #10;   // 0101
        a = 4'b1010; b = 4'b0101; #10;   // 1111
        a = 4'b0000; b = 4'b0000; #10;   // 0000

        // ---------- Cambiar op sin cambiar A ni B ----------
        a = 4'd12; b = 4'd5;
        op = 2'b00; #10;   // suma
        op = 2'b01; #10;   // resta
        op = 2'b10; #10;   // AND
        op = 2'b11; #10;   // OR

        $finish;
    end
endmodule