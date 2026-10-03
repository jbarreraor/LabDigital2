`timescale 1ns/1ps

module tb_OperacionImplementacion;

    // ---- Señales de estímulo / observación ----
    reg        clk;
    reg        andd;
    reg        orr;
    reg        reset;
    reg  [3:0] a;
    reg  [3:0] sw;
    wire [2:0] led;
    wire [3:0] y;

    integer errores = 0;

    // ---- Instancia del DUT (Device Under Test) ----
    OperacionImplementacion DUT (
        .clk    (clk),
        .andd   (andd),
        .orr    (orr),
        .reset  (reset),
        .a      (a),
        .sw     (sw),
        .led    (led),
        .y      (y)
    );

    // ---- Generación de reloj: periodo 8 ns (125 MHz, igual que el XDC) ----
    initial clk = 1'b0;
    always #4 clk = ~clk;

    // ---- Tarea de verificación automática ----
    task check_output;
        input [3:0] y_esp;
        input [2:0] led_esp;
        input [319:0] etiqueta;
        begin
            if (y !== y_esp || led !== led_esp) begin
                errores = errores + 1;
                $display("[FALLO] t=%0t %-0s | esperado y=%b led=%b | obtenido y=%b led=%b",
                          $time, etiqueta, y_esp, led_esp, y, led);
            end else begin
                $display("[OK]    t=%0t %-0s | y=%b led=%b", $time, etiqueta, y, led);
            end
        end
    endtask

    initial begin
        // ---- Dump para GTKWave ----
        $dumpfile("OperacionImplementacion.vcd");
        $dumpvars(0, tb_OperacionImplementacion);

        // Valores iniciales
        andd  = 0; orr = 0; reset = 1;
        a     = 4'b0000; sw = 4'b0000;

        // ---- Reset inicial ----
        @(negedge clk);
        @(negedge clk);
        check_output(4'b0000, 3'b100, "Reset activo (OFF)");

        reset = 0;
        a  = 4'b1100;
        sw = 4'b1010;

        // ---- Caso 1: ningun selector activo -> OFF ----
        andd = 0; orr = 0;
        @(negedge clk); @(negedge clk);
        check_output(4'b0000, 3'b100, "andd=0 orr=0 (OFF)");

        // ---- Caso 2: solo orr -> OR ----
        andd = 0; orr = 1;
        @(negedge clk); @(negedge clk);
        check_output(a | sw, 3'b010, "andd=0 orr=1 (OR)");

        // Cambiar operandos estando en modo OR
        a = 4'b0110; sw = 4'b0011;
        @(negedge clk);
        check_output(a | sw, 3'b010, "OR con nuevos operandos");

        // ---- Caso 3: solo andd -> AND ----
        andd = 1; orr = 0;
        @(negedge clk); @(negedge clk);
        check_output(a & sw, 3'b001, "andd=1 orr=0 (AND)");

        a = 4'b1111; sw = 4'b1010;
        @(negedge clk);
        check_output(a & sw, 3'b001, "AND con nuevos operandos");

        // ---- Caso 4: ambos activos a la vez -> por defecto OFF ----
        andd = 1; orr = 1;
        @(negedge clk); @(negedge clk);
        check_output(4'b0000, 3'b100, "andd=1 orr=1 (OFF por defecto)");

        // ---- Caso 5: volver a AND y luego reset asincrono en medio del clk ----
        andd = 1; orr = 0;
        @(negedge clk); @(negedge clk);
        check_output(a & sw, 3'b001, "Vuelta a AND antes del reset asincrono");

        #2 reset = 1;              // reset asincrono, no alineado a flanco de reloj
        #1 check_output(4'b0000, 3'b100, "Reset asincrono forzado (OFF inmediato)");
        #3 reset = 0;

        // Con andd=1/orr=0 aun sostenidos, el siguiente flanco de reloj
        // regresa al DUT a modo AND (el reset solo fuerza OFF mientras esta activo)
        @(negedge clk); @(negedge clk);
        check_output(a & sw, 3'b001, "Tras liberar reset, vuelve a AND (andd=1 sostenido)");

        // ---- Caso 6: barrido de todas las combinaciones de a y sw en modo AND ----
        andd = 1; orr = 0;
        a = 4'b0000;
        repeat (4) begin
            sw = 4'b0000;
            repeat (4) begin
                @(negedge clk);
                check_output(a & sw, 3'b001, "Barrido AND");
                sw = sw + 4'b0101;
            end
            a = a + 4'b0011;
        end

        // ---- Resumen ----
        @(negedge clk);
        if (errores == 0)
            $display("\n==== TESTBENCH COMPLETO: TODOS LOS CASOS PASARON ====");
        else
            $display("\n==== TESTBENCH COMPLETO: %0d FALLO(S) DETECTADO(S) ====", errores);

        $finish;
    end

endmodule
