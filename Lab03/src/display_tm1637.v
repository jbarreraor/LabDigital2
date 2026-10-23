// ====================================================================
// Modulo: display_tm1637.v
// Descripcion: Controlador para display de 4 digitos y 7 segmentos TM1637.
//              Convierte el resultado de 8 bits de la ALU (con signo)
//              a formato decimal (o hex) y lo transmite mediante el
//              protocolo serie de 2 hilos del TM1637.
// ====================================================================

`timescale 1ns / 1ps

module display_tm1637 #(
    parameter CLK_FREQ_HZ = 125_000_000,
    parameter BIT_FREQ_HZ = 100_000,
    parameter IDLE_TICKS  = 2000,        // Intervalo de refresco (~10 ms a 100 kHz)
    parameter [2:0] BRIGHTNESS = 3'd2    // Brillo intermedio (0=min, 7=max)
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] value,             // Resultado de 8 bits a mostrar
    input  wire       negative,          // 1 si la resta dio resultado negativo
    input  wire       hex_mode,          // 0 = Decimal con signo, 1 = Hexadecimal
    output reg        scl,               // Linea de reloj hacia TM1637
    inout  wire       sda                // Linea de datos bidireccional
);

    // ----------------------------------------------------------------
    // 1. Manejo Open-Drain de SDA
    // ----------------------------------------------------------------
    reg sda_out;
    assign sda = sda_out ? 1'bz : 1'b0;

    // ----------------------------------------------------------------
    // 2. Base de tiempo (Ticks a 2x la frecuencia del bus)
    // ----------------------------------------------------------------
    localparam HALF_PERIOD = CLK_FREQ_HZ / (2 * BIT_FREQ_HZ);

    reg [$clog2(HALF_PERIOD):0] div_cnt;
    wire tick = (div_cnt == HALF_PERIOD - 1);

    always @(posedge clk) begin
        if (rst) begin
            div_cnt <= 0;
        end else begin
            if (tick)
                div_cnt <= 0;
            else
                div_cnt <= div_cnt + 1;
        end
    end

    // ----------------------------------------------------------------
    // 3. Conversion BCD y decodificacion de 7 segmentos
    // ----------------------------------------------------------------
    wire [7:0] mag = negative ? (~value + 8'd1) : value;

    wire [3:0] bcd_c = (mag >= 200) ? 4'd2 : (mag >= 100) ? 4'd1 : 4'd0;
    wire [7:0] rem_c = mag - (bcd_c * 8'd100);

    wire [3:0] bcd_d = (rem_c >= 90) ? 4'd9 :
                       (rem_c >= 80) ? 4'd8 :
                       (rem_c >= 70) ? 4'd7 :
                       (rem_c >= 60) ? 4'd6 :
                       (rem_c >= 50) ? 4'd5 :
                       (rem_c >= 40) ? 4'd4 :
                       (rem_c >= 30) ? 4'd3 :
                       (rem_c >= 20) ? 4'd2 :
                       (rem_c >= 10) ? 4'd1 : 4'd0;
    wire [3:0] bcd_u = rem_c - (bcd_d * 8'd10);

    function [7:0] seg7;
        input [3:0] d;
        case (d)
            4'h0: seg7 = 8'b0011_1111; // 0x3F
            4'h1: seg7 = 8'b0000_0110; // 0x06
            4'h2: seg7 = 8'b0101_1011; // 0x5B
            4'h3: seg7 = 8'b0100_1111; // 0x4F
            4'h4: seg7 = 8'b0110_0110; // 0x66
            4'h5: seg7 = 8'b0110_1101; // 0x6D
            4'h6: seg7 = 8'b0111_1101; // 0x7D
            4'h7: seg7 = 8'b0000_0111; // 0x07
            4'h8: seg7 = 8'b0111_1111; // 0x7F
            4'h9: seg7 = 8'b0110_1111; // 0x6F
            4'hA: seg7 = 8'b0111_0111; // 0x77
            4'hB: seg7 = 8'b0111_1100; // 0x7C
            4'hC: seg7 = 8'b0011_1001; // 0x39
            4'hD: seg7 = 8'b0101_1110; // 0x5E
            4'hE: seg7 = 8'b0111_1001; // 0x79
            4'hF: seg7 = 8'b0111_0001; // 0x71
            default: seg7 = 8'b0000_0000;
        endcase
    endfunction

    localparam SEG_MINUS = 8'b0100_0000; // '-'
    localparam SEG_BLANK = 8'b0000_0000; // Apagado

    reg [7:0] dig0, dig1, dig2, dig3;

    always @(*) begin
        if (hex_mode) begin
            dig0 = SEG_BLANK;
            dig1 = SEG_BLANK;
            dig2 = seg7(value[7:4]);
            dig3 = seg7(value[3:0]);
        end else begin
            if (negative) begin
                if (mag >= 100) begin
                    dig0 = SEG_MINUS;
                    dig1 = seg7(bcd_c);
                    dig2 = seg7(bcd_d);
                    dig3 = seg7(bcd_u);
                end else if (mag >= 10) begin
                    dig0 = SEG_BLANK;
                    dig1 = SEG_MINUS;
                    dig2 = seg7(bcd_d);
                    dig3 = seg7(bcd_u);
                end else begin
                    dig0 = SEG_BLANK;
                    dig1 = SEG_BLANK;
                    dig2 = SEG_MINUS;
                    dig3 = seg7(bcd_u);
                end
            end else begin
                if (mag >= 100) begin
                    dig0 = SEG_BLANK;
                    dig1 = seg7(bcd_c);
                    dig2 = seg7(bcd_d);
                    dig3 = seg7(bcd_u);
                end else if (mag >= 10) begin
                    dig0 = SEG_BLANK;
                    dig1 = SEG_BLANK;
                    dig2 = seg7(bcd_d);
                    dig3 = seg7(bcd_u);
                end else begin
                    dig0 = SEG_BLANK;
                    dig1 = SEG_BLANK;
                    dig2 = SEG_BLANK;
                    dig3 = seg7(bcd_u);
                end
            end
        end
    end

    // ----------------------------------------------------------------
    // 4. Maquina de Estados FSM
    // ----------------------------------------------------------------
    localparam [3:0]
        ST_IDLE      = 4'd0,
        ST_START_0   = 4'd1,
        ST_START_1   = 4'd2,
        ST_START_2   = 4'd3,
        ST_BIT_LOW   = 4'd4,
        ST_BIT_HIGH  = 4'd5,
        ST_ACK_LOW   = 4'd6,
        ST_ACK_HIGH  = 4'd7,
        ST_STOP_0    = 4'd8,
        ST_STOP_1    = 4'd9,
        ST_STOP_2    = 4'd10,
        ST_STOP_3    = 4'd11;

    reg [3:0]  state;
    reg [2:0]  byte_idx;
    reg [2:0]  bit_idx;
    reg [15:0] idle_cnt;

    reg [7:0] latched_dig0, latched_dig1, latched_dig2, latched_dig3;
    reg [7:0] last_value;
    reg       last_negative;

    reg [7:0] current_byte;
    always @(*) begin
        case (byte_idx)
            3'd0: current_byte = 8'h40; // Auto-incremento
            3'd1: current_byte = 8'hC0; // Direccion digito 0
            3'd2: current_byte = latched_dig0;
            3'd3: current_byte = latched_dig1;
            3'd4: current_byte = latched_dig2;
            3'd5: current_byte = latched_dig3;
            3'd6: current_byte = {4'b1000, 1'b1, BRIGHTNESS}; // Display ON
            default: current_byte = 8'h00;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            state         <= ST_IDLE;
            byte_idx      <= 3'd0;
            bit_idx       <= 3'd0;
            idle_cnt      <= 16'd0;
            scl           <= 1'b1;
            sda_out       <= 1'b1;
            latched_dig0  <= 8'h00;
            latched_dig1  <= 8'h00;
            latched_dig2  <= 8'h00;
            latched_dig3  <= 8'h00;
            last_value    <= 8'hFF;
            last_negative <= 1'b0;
        end else if (tick) begin
            case (state)
                ST_IDLE: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    if ((value != last_value) || (negative != last_negative) || (idle_cnt >= IDLE_TICKS)) begin
                        idle_cnt      <= 16'd0;
                        last_value    <= value;
                        last_negative <= negative;
                        latched_dig0  <= dig0;
                        latched_dig1  <= dig1;
                        latched_dig2  <= dig2;
                        latched_dig3  <= dig3;
                        byte_idx      <= 3'd0;
                        state         <= ST_START_0;
                    end else begin
                        idle_cnt <= idle_cnt + 1'b1;
                    end
                end

                // Condicion START: SDA baja mientras SCL esta en alto
                ST_START_0: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    state   <= ST_START_1;
                end

                ST_START_1: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b0; // Flanco START
                    state   <= ST_START_2;
                end

                ST_START_2: begin
                    scl     <= 1'b0; // SCL baja
                    sda_out <= 1'b0;
                    bit_idx <= 3'd0;
                    state   <= ST_BIT_LOW;
                end

                // Transmision de bits
                ST_BIT_LOW: begin
                    scl     <= 1'b0;
                    sda_out <= current_byte[bit_idx];
                    state   <= ST_BIT_HIGH;
                end

                ST_BIT_HIGH: begin
                    scl <= 1'b1;
                    if (bit_idx == 3'd7) begin
                        state <= ST_ACK_LOW;
                    end else begin
                        bit_idx <= bit_idx + 1'b1;
                        state   <= ST_BIT_LOW;
                    end
                end

                // Ciclo de ACK
                ST_ACK_LOW: begin
                    scl     <= 1'b0;
                    sda_out <= 1'b1; // Liberar SDA
                    state   <= ST_ACK_HIGH;
                end

                ST_ACK_HIGH: begin
                    scl <= 1'b1;
                    if (byte_idx == 3'd0 || byte_idx == 3'd5 || byte_idx == 3'd6) begin
                        state <= ST_STOP_0;
                    end else begin
                        byte_idx <= byte_idx + 1'b1;
                        bit_idx  <= 3'd0;
                        state    <= ST_BIT_LOW;
                    end
                end

                // Condicion STOP: SDA sube mientras SCL esta en alto
                ST_STOP_0: begin
                    scl     <= 1'b0;
                    sda_out <= 1'b0;
                    state   <= ST_STOP_1;
                end

                ST_STOP_1: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b0;
                    state   <= ST_STOP_2;
                end

                ST_STOP_2: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1; // Flanco STOP
                    state   <= ST_STOP_3;
                end

                ST_STOP_3: begin
                    scl     <= 1'b1;
                    sda_out <= 1'b1;
                    if (byte_idx == 3'd0) begin
                        byte_idx <= 3'd1;
                        state    <= ST_START_0;
                    end else if (byte_idx == 3'd5) begin
                        byte_idx <= 3'd6;
                        state    <= ST_START_0;
                    end else begin
                        state    <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
