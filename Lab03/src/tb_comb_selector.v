`timescale 1ns / 1ps

module tb_comb_selector;

    // Entradas del DUT
    reg clk;
    reg enable;

    // Salidas del DUT
    wire [1:0] addr_a;
    wire [1:0] addr_b;
    wire [3:0] leds;

    integer i;

    // Instancia del modulo bajo prueba (DUT)
    comb_selector dut (
        .clk(clk),
        .enable(enable),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .leds(leds)
    );

    // Generacion del archivo VCD para GTKWave
    initial begin
        $dumpfile("tb_comb_selector.vcd");
        $dumpvars(0, tb_comb_selector);
    end

    // Reloj: periodo de 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Tarea: pulso de enable de exactamente un ciclo de reloj
    task pulso_enable;
        begin
            @(negedge clk);
            enable = 1;
            @(negedge clk);
            enable = 0;
            #1;
        end
    endtask

    // Tarea: comprueba direcciones y LEDs contra lo esperado
    task check(input [1:0] ea, input [1:0] eb);
        reg [3:0] eleds;
        begin
            eleds = (4'b0001 << ea) | (4'b0001 << eb);
            if (addr_a !== ea || addr_b !== eb || leds !== eleds)
                $fatal(1, "ERROR: esperado A=%0d B=%0d LEDs=%b, obtenido A=%0d B=%0d LEDs=%b",
                       ea, eb, eleds, addr_a, addr_b, leds);
            else
                $display("OK: A=R%0d B=R%0d LEDs=%b", addr_a, addr_b, leds);
        end
    endtask

    initial begin
        // Entrada inicial
        enable = 0;
        #1;

        // Prueba 1: estado inicial (R0, R0)
        check(2'd0, 2'd0);

        // Prueba 2: sin enable el indice no cambia
        repeat (5) @(posedge clk);
        #1;
        check(2'd0, 2'd0);
        $display("OK: sin enable no avanza");

        // Prueba 3: recorrer los 16 pares, un pulso por paso
        for (i = 0; i < 16; i = i + 1) begin
            check(i / 4, i % 4);
            pulso_enable;
        end

        // Prueba 4: tras el ultimo par vuelve a (R0, R0)
        check(2'd0, 2'd0);
        $display("OK: vuelve al inicio tras 16 pasos");

        $display("--------------------------------");
        $display("Todas las pruebas del selector pasaron.");
        $display("--------------------------------");

        $finish;
    end

endmodule