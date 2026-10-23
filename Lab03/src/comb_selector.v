module comb_selector (
    input  wire       clk,
    input  wire       enable,
    output wire [1:0] addr_a,
    output wire [1:0] addr_b,
    output wire [3:0] leds
);

    reg [3:0] index;

    // Valor de arranque (simulación y FPGA)
    initial begin
        index = 4'd0;
    end

    // El indice avanza una posición con cada pulso de enable
    always @(posedge clk) begin
        if (enable)
            index <= index + 1'b1;
    end

    // Direcciones de los operandos
    assign addr_a = index[3:2];
    assign addr_b = index[1:0];

    // LED i encendido si el registro i es A o B
    assign leds[0] = (addr_a == 2'd0) || (addr_b == 2'd0);
    assign leds[1] = (addr_a == 2'd1) || (addr_b == 2'd1);
    assign leds[2] = (addr_a == 2'd2) || (addr_b == 2'd2);
    assign leds[3] = (addr_a == 2'd3) || (addr_b == 2'd3);

endmodule