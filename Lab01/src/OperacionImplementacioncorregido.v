module OperacionImplementacion_corregida(
    input clk,
    input andd,
    input orr,
    input reset,
    input [3:0] a,
    input [3:0] sw,
    output reg [2:0] led,
    output reg [3:0] y
    );

    // Estados
    localparam OFF_ST = 3'b000;
    localparam SUM_ST = 3'b001;
    localparam OR_ST  = 3'b010;
    localparam AND_ST = 3'b011;
    localparam XOR_ST = 3'b100;

    reg [2:0] state = OFF_ST;

    // ---- Logica secuencial: transicion de estados ----
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= OFF_ST;
        end
        else begin
            case ({andd, orr})
                2'b00:   state <= SUM_ST;
                2'b01:   state <= OR_ST;
                2'b10:   state <= AND_ST;
                2'b11:   state <= XOR_ST;
                default: state <= OFF_ST;
            endcase
        end
    end

    // ---- Logica combinacional: salidas segun el estado ----
    always @(*) begin
        case (state)

            SUM_ST: begin
                y   = a + sw;
                led = 3'b011;
            end

            OR_ST: begin
                y   = a | sw;
                led = 3'b010;
            end

            AND_ST: begin
                y   = a & sw;
                led = 3'b001;
            end

            XOR_ST: begin
                y   = a ^ sw;
                led = 3'b100;
            end

            default: begin // OFF_ST
                y   = 4'b0000;
                led = 3'b000;
            end

        endcase
    end

endmodule