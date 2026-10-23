// ====================================================================
// Modulo: top.v
// Descripcion: Modulo superior de integracion para el Laboratorio 03.
//              Integra Banco de Registros, Selector de Combinaciones,
//              ALU de 4 bits, visualizacion en TM1637, manejo de
//              pulsadores con antirrebote y mapeo de E/S de la Zybo Z7.
// ====================================================================

`timescale 1ns / 1ps

module top #(
    // Parametros configurables (reducibles para simulaciones ultrarrapidas)
    parameter DEBOUNCE_CYCLES = 1_250_000, // ~10 ms a 125 MHz
    parameter CLK_FREQ_HZ     = 125_000_000,
    parameter BIT_FREQ_HZ     = 100_000
)(
    input  wire       clk,        // Reloj del sistema de 125 MHz (K17)
    input  wire       reset,      // Reset activo en alto (con pulldown)
    input  wire [3:0] sw,         // SW[3:0]: Dato / SW[2:0]: Operacion ALU
    input  wire [3:0] btn,        // BTN0..BTN3 de la placa
    output wire [3:0] led,        // LED0..LED3: Registros activos en operacion
    output reg  [2:0] rgb_led,    // LED RGB: Registro seleccionado para escritura
    output wire       tm1637_clk, // Pin CLK del display TM1637
    inout  wire       tm1637_dio  // Pin DIO bidireccional del TM1637
);

    // ================================================================
    // 1. Antirrebote y sincronizacion de los 4 pulsadores
    // ================================================================
    // Cada pulsador genera un pulso limpio de exactamente 1 ciclo de reloj.
    wire pulse_btn0; // Seleccionar registro de escritura
    wire pulse_btn1; // Escribir dato en registro
    wire pulse_btn2; // Cambiar combinacion de operandos
    wire pulse_btn3; // Ejecutar ALU y actualizar pantalla

    debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db0 (
        .clk(clk), .rst(reset), .btn_in(btn[0]), .btn_pulse(pulse_btn0)
    );
    debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db1 (
        .clk(clk), .rst(reset), .btn_in(btn[1]), .btn_pulse(pulse_btn1)
    );
    debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db2 (
        .clk(clk), .rst(reset), .btn_in(btn[2]), .btn_pulse(pulse_btn2)
    );
    debouncer #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) db3 (
        .clk(clk), .rst(reset), .btn_in(btn[3]), .btn_pulse(pulse_btn3)
    );

    // ================================================================
    // 2. Registro de seleccion de escritura y LED RGB
    // ================================================================
    // BTN0 cicla la direccion de escritura: R0 -> R1 -> R2 -> R3 -> R0
    reg [1:0] write_reg_sel;

    always @(posedge clk) begin
        if (reset)
            write_reg_sel <= 2'b00;
        else if (pulse_btn0)
            write_reg_sel <= write_reg_sel + 1'b1;
    end

    // Codificacion de color en LED RGB segun el registro seleccionado:
    // rgb_led[0] = Azul, rgb_led[1] = Verde, rgb_led[2] = Rojo
    always @(*) begin
        case (write_reg_sel)
            2'b00:   rgb_led = 3'b001; // R0: Azul
            2'b01:   rgb_led = 3'b010; // R1: Verde
            2'b10:   rgb_led = 3'b100; // R2: Rojo
            2'b11:   rgb_led = 3'b011; // R3: Cian (Azul + Verde)
            default: rgb_led = 3'b000;
        endcase
    end

    // ================================================================
    // 3. Selector de combinaciones de operandos
    // ================================================================
    // Genera las direcciones (addr_a, addr_b) a partir de BTN2 y
    // enciende los LEDs correspondientes a los registros activos.
    wire [1:0] addr_a;
    wire [1:0] addr_b;

    comb_selector u_comb_selector (
        .clk    (clk),
        .enable (pulse_btn2),
        .addr_a (addr_a),
        .addr_b (addr_b),
        .leds   (led)
    );

    // ================================================================
    // 4. Banco de Registros (4 registros de 4 bits)
    // ================================================================
    // Escritura sincrona con BTN1.
    // Dos puertos de lectura asincrona para operandos A y B.
    wire [3:0] operand_a;
    wire [3:0] operand_b;

    reg_bank u_reg_bank (
        .clk          (clk),
        .write_enable (pulse_btn1),
        .write_addr   (write_reg_sel),
        .write_data   (sw[3:0]),
        .read_addr_a  (addr_a),
        .read_data_a  (operand_a),
        .read_addr_b  (addr_b),
        .read_data_b  (operand_b)
    );

    // ================================================================
    // 5. Unidad Aritmetico Logica (ALU) de 4 bits
    // ================================================================
    // Circuito combinacional puro. La operacion se selecciona con SW[2:0].
    wire [7:0] alu_result;
    wire       alu_negative;

    alu u_alu (
        .operand_a (operand_a),
        .operand_b (operand_b),
        .operation (sw[2:0]),
        .result    (alu_result),
        .negative  (alu_negative)
    );

    // ================================================================
    // 6. Registro de retencion del resultado (Latching con BTN3)
    // ================================================================
    // Requisito fundamental: el display conserva el ultimo resultado
    // ejecutado aunque cambien los operandos, la combinacion o la operacion.
    reg [7:0] displayed_result;
    reg       displayed_negative;

    always @(posedge clk) begin
        if (reset) begin
            displayed_result   <= 8'd0;
            displayed_negative <= 1'b0;
        end else if (pulse_btn3) begin
            displayed_result   <= alu_result;
            displayed_negative <= alu_negative;
        end
    end

    // ================================================================
    // 7. Modulo de visualizacion TM1637
    // ================================================================
    display_tm1637 #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BIT_FREQ_HZ (BIT_FREQ_HZ)
    ) u_display (
        .clk      (clk),
        .rst      (reset),
        .value    (displayed_result),
        .negative (displayed_negative),
        .hex_mode (1'b0), // 0: Formato decimal con signo
        .scl      (tm1637_clk),
        .sda      (tm1637_dio)
    );

endmodule
