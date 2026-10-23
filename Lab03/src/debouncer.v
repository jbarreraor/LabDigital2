// ====================================================================
// Modulo: debouncer.v
// Descripcion: Filtro antirrebote con sincronizador de 2 etapas y
//              detector de flanco de subida (genera un pulso de 1 ciclo).
// ====================================================================

`timescale 1ns / 1ps

module debouncer #(
    parameter DEBOUNCE_CYCLES = 1_250_000 // ~10 ms @ 125 MHz (en simulacion se reduce)
)(
    input  wire clk,
    input  wire rst,
    input  wire btn_in,
    output reg  btn_pulse // Pulso limpio de exactamente 1 ciclo de reloj
);

    // 1. Sincronizador de dos flip-flops para evitar metaestabilidad
    reg sync_0;
    reg sync_1;

    always @(posedge clk) begin
        if (rst) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= btn_in;
            sync_1 <= sync_0;
        end
    end

    // 2. Temporizador antirrebote y generacion de pulso en flanco
    reg [$clog2(DEBOUNCE_CYCLES):0] timer;
    reg state;

    always @(posedge clk) begin
        if (rst) begin
            timer     <= 0;
            state     <= 1'b0;
            btn_pulse <= 1'b0;
        end else begin
            btn_pulse <= 1'b0; // Por defecto apagado (dura solo 1 ciclo)

            if (sync_1 != state) begin
                timer <= timer + 1'b1;
                if (timer >= DEBOUNCE_CYCLES) begin
                    state <= sync_1;
                    timer <= 0;
                    // Si el nuevo estado estable es 1 (flanco de subida), generamos el pulso
                    if (sync_1 == 1'b1) begin
                        btn_pulse <= 1'b1;
                    end
                end
            end else begin
                timer <= 0;
            end
        end
    end

endmodule
