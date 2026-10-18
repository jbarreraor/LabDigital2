module sumador1(
    input a, b, cin,
    output sum, cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

module sumador4(
    input [3:0] a, b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire co1, co2, co3;

    sumador1 s1 (.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(co1));
    sumador1 s2 (.a(a[1]), .b(b[1]), .cin(co1), .sum(sum[1]), .cout(co2));
    sumador1 s3 (.a(a[2]), .b(b[2]), .cin(co2), .sum(sum[2]), .cout(co3));
    sumador1 s4 (.a(a[3]), .b(b[3]), .cin(co3), .sum(sum[3]), .cout(cout));
endmodule

module restador(
    input [3:0] a, b,
    output [3:0] resta
);
    sumador4 resta1 (.a(a), .b(~b), .cin(1'b1), .sum(resta), .cout());
endmodule