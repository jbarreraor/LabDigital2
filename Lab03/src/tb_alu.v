`timescale 1ns / 1ps

module tb_alu;

    // Entradas de la ALU
    reg [3:0] operand_a;
    reg [3:0] operand_b;
    reg [2:0] operation;

    // Salidas de la ALU
    wire [7:0] result;
    wire negative;

    // Instancia del modulo bajo prueba (DUT)
    alu dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .result(result),
        .negative(negative)
    );

    // Generacion del archivo VCD para GTKWave
    initial begin
        $dumpfile("tb_alu.vcd");
        $dumpvars(0, tb_alu);
    end

    initial begin
        // Inicializar entradas
        operand_a = 4'b0000;
        operand_b = 4'b0000;
        operation = 3'b000;

        #1;

        // =========================================
        // PRUEBAS DE SUMA
        // =========================================

        // Prueba 1: 6 + 3 = 9
        operand_a = 4'd6;
        operand_b = 4'd3;
        operation = 3'b000;
        #1;

        if (result !== 8'd9)
            $fatal(1, "ERROR: suma normal");
        else
            $display("OK: suma normal");

        // Prueba 2: 15 + 15 = 30
        operand_a = 4'd15;
        operand_b = 4'd15;
        operation = 3'b000;
        #1;

        if (result !== 8'd30)
            $fatal(1, "ERROR: suma maxima");
        else
            $display("OK: suma maxima");

        // =========================================
        // PRUEBAS DE RESTA
        // =========================================

        // Prueba 3: 9 - 4 = 5
        operand_a = 4'd9;
        operand_b = 4'd4;
        operation = 3'b001;
        #1;

        if (result !== 8'd5)
            $fatal(1, "ERROR: resta positiva");
        else
            $display("OK: resta positiva");

        // Prueba 4: 7 - 7 = 0
        operand_a = 4'd7;
        operand_b = 4'd7;
        operation = 3'b001;
        #1;

        if (result !== 8'd0)
            $fatal(1, "ERROR: resta cero");
        else
            $display("OK: resta cero");

        // Prueba 5: 3 - 5 = -2
        // En 8 bits, complemento a dos: 11111110
        // El flag negative debe valer 1
        operand_a = 4'd3;
        operand_b = 4'd5;
        operation = 3'b001;
        #1;

        if (result !== 8'b11111110 || negative !== 1'b1)
            $fatal(1, "ERROR: resta negativa");
        else
            $display("OK: resta negativa");

        // =========================================
        // PRUEBAS DE MULTIPLICACION
        // =========================================

        // Prueba 6: 15 * 15 = 225
        // El bit 7 vale 1, pero negative debe seguir en 0
        operand_a = 4'd15;
        operand_b = 4'd15;
        operation = 3'b010;
        #1;

        if (result !== 8'd225 || negative !== 1'b0)
            $fatal(1, "ERROR: multiplicacion maxima");
        else
            $display("OK: multiplicacion maxima");

        // Prueba 7: 12 * 0 = 0
        operand_a = 4'd12;
        operand_b = 4'd0;
        operation = 3'b010;
        #1;

        if (result !== 8'd0)
            $fatal(1, "ERROR: multiplicacion por cero");
        else
            $display("OK: multiplicacion por cero");

        // =========================================
        // PRUEBAS DE MODULO
        // =========================================

        // Prueba 8: 11 % 4 = 3
        operand_a = 4'd11;
        operand_b = 4'd4;
        operation = 3'b011;
        #1;

        if (result !== 8'd3)
            $fatal(1, "ERROR: modulo normal");
        else
            $display("OK: modulo normal");

        // Prueba 9: 3 % 5 = 3
        operand_a = 4'd3;
        operand_b = 4'd5;
        operation = 3'b011;
        #1;

        if (result !== 8'd3)
            $fatal(1, "ERROR: modulo con A menor que B");
        else
            $display("OK: modulo con A menor que B");

        // Prueba 10: 9 % 0 = 0
        // Convencion definida en nuestra ALU
        operand_a = 4'd9;
        operand_b = 4'd0;
        operation = 3'b011;
        #1;

        if (result !== 8'd0)
            $fatal(1, "ERROR: modulo entre cero");
        else
            $display("OK: modulo entre cero");

        // =========================================
        // PRUEBAS LOGICAS
        // =========================================

        // Operandos para las operaciones logicas:
        // A = 1010, B = 0110

        // Prueba 11: AND = 0010
        operand_a = 4'b1010;
        operand_b = 4'b0110;
        operation = 3'b100;
        #1;

        if (result !== 8'b00000010)
            $fatal(1, "ERROR: AND");
        else
            $display("OK: AND");

        // Prueba 12: OR = 1110
        operand_a = 4'b1010;
        operand_b = 4'b0110;
        operation = 3'b101;
        #1;

        if (result !== 8'b00001110)
            $fatal(1, "ERROR: OR");
        else
            $display("OK: OR");

        // Prueba 13: XOR = 1100
        operand_a = 4'b1010;
        operand_b = 4'b0110;
        operation = 3'b110;
        #1;

        if (result !== 8'b00001100)
            $fatal(1, "ERROR: XOR");
        else
            $display("OK: XOR");

        // =========================================
        // PRUEBA DEL CODIGO SIN USO
        // =========================================

        // Prueba 14: codigo 111 sin uso -> resultado 0
        operand_a = 4'd9;
        operand_b = 4'd5;
        operation = 3'b111;
        #1;

        if (result !== 8'd0)
            $fatal(1, "ERROR: codigo 111");
        else
            $display("OK: codigo 111 devuelve 0");

        // =========================================
        // FIN DE LAS PRUEBAS
        // =========================================

        $display("--------------------------------");
        $display("Todas las pruebas de la ALU pasaron.");
        $display("--------------------------------");

        $finish;
    end

endmodule