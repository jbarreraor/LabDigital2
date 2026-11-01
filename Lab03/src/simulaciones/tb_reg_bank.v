
`timescale 1ns / 1ps

module tb_reg_bank;

    // Entradas del DUT (Device Under Test)
    reg clk;
    reg write_enable;
    reg [1:0] write_addr;
    reg [3:0] write_data;
    reg [1:0] read_addr_a;
    reg [1:0] read_addr_b;

    // Salidas del DUT
    wire [3:0] read_data_a;
    wire [3:0] read_data_b;

    // Instancia del banco de registros
    reg_bank dut (
        .clk(clk),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr_a(read_addr_a),
        .read_data_a(read_data_a),
        .read_addr_b(read_addr_b),
        .read_data_b(read_data_b)
    );

    // Generador de reloj: periodo de 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_reg_bank.vcd");
        $dumpvars(0, tb_reg_bank);

        // Valores iniciales de las entradas
        write_enable = 0;

        // Valores iniciales de las entradas
        write_enable = 0;
        write_addr = 0;
        write_data = 0;
        read_addr_a = 0;
        read_addr_b = 0;

        // Esperar a que se inicialice el banco
        #1;

        // Prueba 1: leer los registros inicializados en cero
        if (read_data_a !== 4'b0000 ||
            read_data_b !== 4'b0000)
            $display("ERROR: inicializacion incorrecta");
        else
            $display("OK: inicializacion en cero");

        // Prueba 2: escribir 0011 en R0
        @(negedge clk);
        write_enable = 1;
        write_addr = 2'b00;
        write_data = 4'b0011;

        @(posedge clk);
        #1;
        if (dut.registers[0] !== 4'b0011)
            $display("ERROR: escritura en R0");
        else
            $display("OK: escritura en R0");

        // Prueba 3: escribir 0101 en R1
        @(negedge clk);
        write_addr = 2'b01;
        write_data = 4'b0101;

        @(posedge clk);
        #1;
        if (dut.registers[1] !== 4'b0101)
            $display("ERROR: escritura en R1");
        else
            $display("OK: escritura en R1");

        // Prueba 4: escribir 1100 en R2
        @(negedge clk);
        write_addr = 2'b10;
        write_data = 4'b1100;

        @(posedge clk);
        #1;
        if (dut.registers[2] !== 4'b1100)
            $display("ERROR: escritura en R2");
        else
            $display("OK: escritura en R2");

        // Prueba 5: escribir 1010 en R3
        @(negedge clk);
        write_addr = 2'b11;
        write_data = 4'b1010;

        @(posedge clk);
        #1;
        if (dut.registers[3] !== 4'b1010)
            $display("ERROR: escritura en R3");
        else
            $display("OK: escritura en R3");

        
        // Prueba 6: leer R0 y R2 simultaneamente
        @(negedge clk);
        write_enable = 0;
        read_addr_a = 2'b00;
        read_addr_b = 2'b10;

        #1;
        if (read_data_a !== 4'b0011 ||
            read_data_b !== 4'b1100)
            $display("ERROR: lectura simultanea");
        else
            $display("OK: lectura simultanea A=0011, B=1100");

        // Prueba 7: write_enable desactivado
        @(negedge clk);
        write_enable = 0;
        write_addr = 2'b00;
        write_data = 4'b1111;

        @(posedge clk);
        #1;
        if (dut.registers[0] !== 4'b0011)
            $display("ERROR: write_enable no bloqueo escritura");
        else
            $display("OK: write_enable bloquea escritura");

        // Prueba 8: leer R1 y R3 simultaneamente
        @(negedge clk);
        read_addr_a = 2'b01;
        read_addr_b = 2'b11;

        #1;
        if (read_data_a !== 4'b0101 ||
            read_data_b !== 4'b1010)
            $display("ERROR: segunda lectura simultanea");
        else
            $display("OK: segunda lectura simultanea A=0101, B=1010");

        $display("Fin de las pruebas");
        $finish;
    end

endmodule
