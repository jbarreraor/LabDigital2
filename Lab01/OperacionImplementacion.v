module OperacionImplementacion(
    input clk,
    input andd,
    input orr,
    input reset,
    input [3:0] a,
    input [3:0] sw,
    output reg [2:0] led,   // LED RGB: led[2]=Rojo, led[1]=Verde, led[0]=Azul
    output reg [3:0] y      // 4 LEDs de resultado
    );

    // Estados: 00 = apagado/invalido, 01 = OR, 10 = AND
    localparam OFF_ST = 2'b00;
    localparam OR_ST  = 2'b01;
    localparam AND_ST = 2'b10;

    reg [1:0] state = OFF_ST;

    // ---- Logica secuencial: transicion de estados ----
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= OFF_ST;
        end
        else begin
            case ({andd, orr})
                2'b10:   state <= AND_ST;  // solo andd presionado
                2'b01:   state <= OR_ST;   // solo orr presionado
                default: state <= OFF_ST;  // 2'b11 (ambos) o 2'b00 (ninguno)
            endcase
        end
    end

    // ---- Logica combinacional: salidas segun el estado ----
    always @(*) begin
        case (state)
            AND_ST: begin
                y   = a & sw;
                led = 3'b001; // Azul
            end
            OR_ST: begin
                y   = a | sw;
                led = 3'b010; // Verde
            end
            default: begin // OFF_ST
                y   = 4'b0000;
                led = 3'b100; // Rojo
            end
        endcase
    end

endmodule


