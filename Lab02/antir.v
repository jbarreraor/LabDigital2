module antirebote #(
    parameter CICLOS = 1_000_000
)(
    input  clk,
    input  btn,
    output reg pulso
);
    reg [1:0]  sync    = 2'b00;
    reg        estable = 1'b0;
    reg        previo  = 1'b0;
    reg [25:0] cont    = 26'd0;

    always @(posedge clk) begin
        sync <= {sync[0], btn};

        if (sync[1] != estable) begin
            if (cont == CICLOS - 1) begin
                estable <= sync[1];
                cont    <= 26'd0;
            end else
                cont <= cont + 1'b1;
        end else
            cont <= 26'd0;

        previo <= estable;
        pulso  <= estable & ~previo;   // flanco de subida
    end
endmodule