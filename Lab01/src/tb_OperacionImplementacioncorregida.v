`timescale 1ns/1ps

module tb_OperacionImplementacion_corregida;

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

    // ---- Instancia del DUT ----
    OperacionImplementacion_corregida DUT (
        .clk    (clk),
        .andd   (andd),
        .orr    (orr),
        .reset  (reset),
        .a      (a),
        .sw     (sw),
        .led    (led),
        .y      (y)
    );

    // ---- Reloj: periodo 8 ns (125 MHz) ----
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
            end
            else begin
                $display("[OK]    t=%0t %-0s | y=%b led=%b",
                          $time, etiqueta, y, led);
            end
        end
    endtask

    initial begin

        // ---- Dump para GTKWave ----
        $dumpfile("OperacionImplementacion_corregida.vcd");
        $dumpvars(0, tb_OperacionImplementacion_corregida);

        // Valores iniciales
        andd = 0;
        orr = 0;
        reset = 1;
        a = 4'b0000;
        sw = 4'b0000;

        // ---- Reset inicial ----
        @(negedge clk);
        @(negedge clk);
        check_output(
            4'b0000,
            3'b000,
            "Reset activo (OFF)"
        );

        reset = 0;

        // ==================================================
        // CASO 1: SUMA
        // andd=0, orr=0
        // ==================================================

        a  = 4'b0011; // 3
        sw = 4'b0100; // 4
        andd = 0;
        orr = 0;

        @(negedge clk);
        @(negedge clk);

        check_output(
            a + sw,
            3'b011,
            "andd=0 orr=0 (SUMA)"
        );

        // ==================================================
        // CASO 2: OR
        // andd=0, orr=1
        // ==================================================

        a  = 4'b1100;
        sw = 4'b1010;
        andd = 0;
        orr = 1;

        @(negedge clk);
        @(negedge clk);

        check_output(
            a | sw,
            3'b010,
            "andd=0 orr=1 (OR)"
        );

        // ==================================================
        // CASO 3: AND
        // andd=1, orr=0
        // ==================================================

        a  = 4'b1100;
        sw = 4'b1010;
        andd = 1;
        orr = 0;

        @(negedge clk);
        @(negedge clk);

        check_output(
            a & sw,
            3'b001,
            "andd=1 orr=0 (AND)"
        );

        // ==================================================
        // CASO 4: XOR
        // andd=1, orr=1
        // ==================================================

        a  = 4'b1100;
        sw = 4'b1010;
        andd = 1;
        orr = 1;

        @(negedge clk);
        @(negedge clk);

        check_output(
            a ^ sw,
            3'b100,
            "andd=1 orr=1 (XOR)"
        );

        // ==================================================
        // CASO 5: Reset asincrono
        // ==================================================

        #2 reset = 1;
        #1;

        check_output(
            4'b0000,
            3'b000,
            "Reset asincrono (OFF)"
        );

        #3 reset = 0;

        // Al liberar reset, los selectores siguen en 11,
        // por lo que el sistema debe regresar a XOR.
        @(negedge clk);
        @(negedge clk);

        check_output(
            a ^ sw,
            3'b100,
            "Tras liberar reset vuelve a XOR"
        );

        // ==================================================
        // RESUMEN
        // ==================================================

        @(negedge clk);

        if (errores == 0)
            $display(
                "\n==== TESTBENCH CORREGIDO: TODOS LOS CASOS PASARON ===="
            );
        else
            $display(
                "\n==== TESTBENCH CORREGIDO: %0d FALLO(S) DETECTADO(S) ====",
                errores
            );

        $finish;
    end

endmodule