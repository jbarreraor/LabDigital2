// ====================================================================
// Testbench: tb_top.v
// Descripcion: Verificacion integral del sistema digital completo (top.v)
//              Comprueba:
//              1. Escritura en registros R0-R3 con BTN0 y BTN1.
//              2. Recorrido de combinaciones de operandos con BTN2.
//              3. Indicacion de registros activos en los LEDs.
//              4. Ejecucion de operaciones en la ALU con BTN3.
//              5. Conservacion del resultado ante cambios en switches
//                 o combinaciones hasta una nueva pulsacion de BTN3.
//              6. Manejo de resultados negativos y multiplicacion maxima.
// ====================================================================

`timescale 1ns / 1ps

module tb_top;

    // Entradas del DUT
    reg        clk;
    reg        reset;
    reg  [3:0] sw;
    reg  [3:0] btn;

    // Salidas del DUT
    wire [3:0] led;
    wire [2:0] rgb_led;
    wire       tm1637_clk;
    wire       tm1637_dio;

    // Resistencia pullup fisica en la linea DIO
    pullup (tm1637_dio);

    // Instancia del sistema con temporizadores acelerados para simulacion
    top #(
        .DEBOUNCE_CYCLES (5),      // 5 ciclos para respuesta rapida en testbench
        .CLK_FREQ_HZ     (10_000), // Base de tiempo reducida para simular
        .BIT_FREQ_HZ     (1_000)
    ) dut (
        .clk        (clk),
        .reset      (reset),
        .sw         (sw),
        .btn        (btn),
        .led        (led),
        .rgb_led    (rgb_led),
        .tm1637_clk (tm1637_clk),
        .tm1637_dio (tm1637_dio)
    );

    // Reloj del sistema (100 ns de periodo)
    initial clk = 0;
    always #50 clk = ~clk;

    // Volcado de senales para GTKWave
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    end

    // Tarea para simular la pulsacion de un boton mecanico
    task press_button(input integer btn_idx);
        begin
            @(negedge clk);
            btn[btn_idx] = 1'b1;
            repeat (10) @(posedge clk); // Mantener presionado mas tiempo que DEBOUNCE_CYCLES
            @(negedge clk);
            btn[btn_idx] = 1'b0;
            repeat (10) @(posedge clk); // Dejar en reposo
        end
    endtask

    // ================================================================
    // Secuencia de Pruebas del Sistema
    // ================================================================
    initial begin
        // 0. Inicializacion
        reset = 1'b1;
        sw    = 4'b0000;
        btn   = 4'b0000;

        #200;
        @(negedge clk);
        reset = 1'b0;
        repeat (10) @(posedge clk);

        $display("==================================================");
        $display("INICIO DEL TESTBENCH DEL SISTEMA COMPLETO (top.v)");
        $display("==================================================");

        // ------------------------------------------------------------
        // Paso 1: Escritura en los 4 registros R0, R1, R2, R3
        // ------------------------------------------------------------
        $display("\n[Fase 1] Escribiendo datos en el banco de registros...");

        // R0 = 12 (4'b1100). write_reg_sel arranca en 0 (Azul).
        sw = 4'd12;
        press_button(1); // BTN1: escribir
        if (dut.u_reg_bank.registers[0] !== 4'd12) $fatal(1, "Error escribiendo en R0");
        $display("  R0 cargado con valor %0d. LED RGB = %b (Azul)", dut.u_reg_bank.registers[0], rgb_led);

        // Seleccionar R1 con BTN0
        press_button(0);
        sw = 4'd5;
        press_button(1); // Escribir en R1
        if (dut.u_reg_bank.registers[1] !== 4'd5) $fatal(1, "Error escribiendo en R1");
        $display("  R1 cargado con valor %0d. LED RGB = %b (Verde)", dut.u_reg_bank.registers[1], rgb_led);

        // Seleccionar R2 con BTN0
        press_button(0);
        sw = 4'd15;
        press_button(1); // Escribir en R2
        if (dut.u_reg_bank.registers[2] !== 4'd15) $fatal(1, "Error escribiendo en R2");
        $display("  R2 cargado con valor %0d. LED RGB = %b (Rojo)", dut.u_reg_bank.registers[2], rgb_led);

        // Seleccionar R3 con BTN0
        press_button(0);
        sw = 4'd3;
        press_button(1); // Escribir en R3
        if (dut.u_reg_bank.registers[3] !== 4'd3) $fatal(1, "Error escribiendo en R3");
        $display("  R3 cargado con valor %0d. LED RGB = %b (Cian)", dut.u_reg_bank.registers[3], rgb_led);

        // ------------------------------------------------------------
        // Paso 2: Seleccionar combinacion de operandos con BTN2
        // ------------------------------------------------------------
        $display("\n[Fase 2] Recorriendo combinaciones de operandos con BTN2...");
        // Al inicio comb_selector esta en R0, R0.
        // Avanzamos a R0, R1: A=12, B=5
        press_button(2);
        if (dut.operand_a !== 4'd12 || dut.operand_b !== 4'd5)
            $fatal(1, "Error en combinacion: esperado A=12, B=5. Obtenido A=%0d, B=%0d", dut.operand_a, dut.operand_b);
        // LEDs activos deben ser LED0 y LED1 (4'b0011)
        if (led !== 4'b0011) $fatal(1, "Error en LEDs activos: esperado 0011, obtenido %b", led);
        $display("  Combinacion activa: A=R0(%0d), B=R1(%0d). LEDs=%b", dut.operand_a, dut.operand_b, led);

        // ------------------------------------------------------------
        // Paso 3: Ejecutar Suma (12 + 5 = 17) con BTN3
        // ------------------------------------------------------------
        $display("\n[Fase 3] Ejecutando Operacion: Suma (SW=000)...");
        sw[2:0] = 3'b000; // Operacion Suma
        #100;
        // Antes de presionar BTN3, el display conserva el valor inicial (0)
        if (dut.displayed_result !== 8'd0) $fatal(1, "Error: display no debio actualizarse antes de BTN3");

        press_button(3); // Ejecutar ALU
        if (dut.displayed_result !== 8'd17)
            $fatal(1, "Error en resultado de Suma: esperado 17, obtenido %0d", dut.displayed_result);
        $display("  OK: BTN3 actualizo el resultado a 17 (12 + 5).");

        // ------------------------------------------------------------
        // Paso 4: Comprobar conservacion del resultado
        // ------------------------------------------------------------
        $display("\n[Fase 4] Verificando conservacion del resultado...");
        // Cambiamos los switches de operacion a Multiplicacion (010)
        sw[2:0] = 3'b010;
        #200;
        // El resultado guardado DEBE permanecer inmutable en 17
        if (dut.displayed_result !== 8'd17)
            $fatal(1, "FALLO DE CONSERVACION: El display cambio al mover los switches sin presionar BTN3!");
        $display("  OK: El display retiene 17 tras cambiar operacion a Multiplicacion (sin presionar BTN3).");

        // Cambiamos de combinacion con BTN2
        press_button(2); // Pasa a R0, R2 (A=12, B=15)
        #200;
        if (dut.displayed_result !== 8'd17)
            $fatal(1, "FALLO DE CONSERVACION: El display cambio al cambiar la combinacion sin presionar BTN3!");
        $display("  OK: El display retiene 17 tras cambiar los operandos a R0, R2.");

        // Ahora si presionamos BTN3 para calcular la multiplicacion: 12 * 15 = 180
        press_button(3);
        if (dut.displayed_result !== 8'd180)
            $fatal(1, "Error ejecutando Multiplicacion: esperado 180, obtenido %0d", dut.displayed_result);
        $display("  OK: BTN3 actualizo la multiplicacion a 180 (12 * 15).");

        // ------------------------------------------------------------
        // Paso 5: Probar Resta con resultado negativo
        // ------------------------------------------------------------
        $display("\n[Fase 5] Probando Resta negativa...");
        // Buscamos una combinacion donde A < B.
        // Recorremos hasta tener A=R1 (5) y B=R0 (12)
        // Indice de (R1, R0) es 4.
        while (!(dut.u_comb_selector.addr_a == 2'd1 && dut.u_comb_selector.addr_b == 2'd0)) begin
            press_button(2);
        end
        $display("  Combinacion alcanzada: A=R1(%0d), B=R0(%0d)", dut.operand_a, dut.operand_b);

        sw[2:0] = 3'b001; // Resta: 5 - 12 = -7
        #100;
        press_button(3); // Ejecutar
        // En complemento a 2 de 8 bits, -7 es 8'b11111001 (249)
        if (dut.displayed_result !== 8'b11111001 || dut.displayed_negative !== 1'b1)
            $fatal(1, "Error en resta negativa: esperado -7 (flag=1), obtenido %b (flag=%b)",
                   dut.displayed_result, dut.displayed_negative);
        $display("  OK: Resta 5 - 12 dio resultado negativo (-7) con displayed_negative = 1.");

        $display("\n==================================================");
        $display("TODAS LAS PRUEBAS DEL SISTEMA COMPLETO PASARON CON EXITO!");
        $display("==================================================");

        #5000;
        $finish;
    end

endmodule
