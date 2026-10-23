`timescale 1ns / 1ps

module tb_display_tm1637;

    reg clk;
    reg rst;
    reg [7:0] value;
    reg negative;
    reg hex_mode;

    wire scl;
    wire sda;

    pullup (sda);

    display_tm1637 #(
        .CLK_FREQ_HZ (10_000),
        .BIT_FREQ_HZ (1_000),
        .IDLE_TICKS  (6),
        .BRIGHTNESS  (3'd2)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .value    (value),
        .negative (negative),
        .hex_mode (hex_mode),
        .scl      (scl),
        .sda      (sda)
    );

    initial clk = 0;
    always #50 clk = ~clk;

    initial begin
        $dumpfile("tb_display_tm1637.vcd");
        $dumpvars(0, tb_display_tm1637);
    end

    // Monitor TM1637 con cola FIFO
    reg in_transaction = 0;
    reg [3:0] bit_counter = 0;
    reg [7:0] temp_byte = 0;

    reg [7:0] fifo [0:63];
    integer wr_ptr = 0;
    integer rd_ptr = 0;

    always @(negedge sda) begin
        if (scl === 1'b1) begin
            in_transaction <= 1'b1;
            bit_counter <= 4'd0;
        end
    end

    always @(posedge sda) begin
        if (scl === 1'b1) begin
            in_transaction <= 1'b0;
            bit_counter <= 4'd0;
        end
    end

    always @(posedge scl) begin
        if (in_transaction) begin
            if (bit_counter < 4'd7) begin
                temp_byte[bit_counter] <= sda;
                bit_counter <= bit_counter + 1'b1;
            end else if (bit_counter == 4'd7) begin
                fifo[wr_ptr] <= {sda, temp_byte[6:0]};
                wr_ptr <= wr_ptr + 1;
                bit_counter <= 4'd8; // Siguiente ciclo es ACK
            end else if (bit_counter == 4'd8) begin
                // Ciclo 9: ACK
                bit_counter <= 4'd0; // Listo para siguiente byte
            end
        end
    end

    task get_byte(output [7:0] b);
        begin
            wait(rd_ptr < wr_ptr);
            b = fifo[rd_ptr];
            rd_ptr = rd_ptr + 1;
        end
    endtask

    task get_frame(
        output [7:0] c1,
        output [7:0] c2,
        output [7:0] d0,
        output [7:0] d1,
        output [7:0] d2,
        output [7:0] d3,
        output [7:0] ct
    );
        begin
            get_byte(c1);
            get_byte(c2);
            get_byte(d0);
            get_byte(d1);
            get_byte(d2);
            get_byte(d3);
            get_byte(ct);
        end
    endtask

    reg [7:0] b_c1, b_c2, b_d0, b_d1, b_d2, b_d3, b_ct;

    initial begin
        rst      = 1;
        value    = 8'd0;
        negative = 0;
        hex_mode = 0;

        #500;
        @(negedge clk);
        rst = 0;

        $display("==================================================");
        $display("INICIO DE PRUEBAS DEL CONTROLADOR TM1637");
        $display("==================================================");

        // Prueba 1: 0 en decimal -> "   0"
        $display("\n[Prueba 1] Valor = 0 (Decimal)");
        get_frame(b_c1, b_c2, b_d0, b_d1, b_d2, b_d3, b_ct);
        $display("  Recibido: CMD1=0x%02X, CMD2=0x%02X, D0=0x%02X, D1=0x%02X, D2=0x%02X, D3=0x%02X, CTRL=0x%02X",
                 b_c1, b_c2, b_d0, b_d1, b_d2, b_d3, b_ct);

        if (b_c1 !== 8'h40 || b_c2 !== 8'hC0 || b_ct !== 8'h8A)
            $fatal(1, "ERROR en tramas de control");
        if (b_d0 === 8'h00 && b_d1 === 8'h00 && b_d2 === 8'h00 && b_d3 === 8'h3F)
            $display("  OK: Digitos corresponden a '   0'");
        else
            $fatal(1, "ERROR: esperado 00 00 00 3F, obtenido %02X %02X %02X %02X", b_d0, b_d1, b_d2, b_d3);

        // Prueba 2: 225 en decimal (15*15) -> " 225"
        $display("\n[Prueba 2] Valor = 225 (Decimal: 15*15)");
        @(negedge clk);
        value = 8'd225;
        get_frame(b_c1, b_c2, b_d0, b_d1, b_d2, b_d3, b_ct);
        $display("  Recibido: D0=0x%02X, D1=0x%02X, D2=0x%02X, D3=0x%02X", b_d0, b_d1, b_d2, b_d3);
        if (b_d0 === 8'h00 && b_d1 === 8'h5B && b_d2 === 8'h5B && b_d3 === 8'h6D)
            $display("  OK: Digitos corresponden a ' 225'");
        else
            $fatal(1, "ERROR: esperado 00 5B 5B 6D, obtenido %02X %02X %02X %02X", b_d0, b_d1, b_d2, b_d3);

        // Prueba 3: -4 (Resta) -> "  -4"
        $display("\n[Prueba 3] Valor = -4 (Resta negativa)");
        @(negedge clk);
        value    = 8'hFC; // Complemento a 2
        negative = 1'b1;
        get_frame(b_c1, b_c2, b_d0, b_d1, b_d2, b_d3, b_ct);
        $display("  Recibido: D0=0x%02X, D1=0x%02X, D2=0x%02X, D3=0x%02X", b_d0, b_d1, b_d2, b_d3);
        if (b_d0 === 8'h00 && b_d1 === 8'h00 && b_d2 === 8'h40 && b_d3 === 8'h66)
            $display("  OK: Digitos corresponden a '  -4'");
        else
            $fatal(1, "ERROR: esperado 00 00 40 66, obtenido %02X %02X %02X %02X", b_d0, b_d1, b_d2, b_d3);

        // Prueba 4: 0xA5 en hexadecimal -> "  A5"
        $display("\n[Prueba 4] Valor = 0xA5 (Hexadecimal)");
        @(negedge clk);
        value    = 8'hA5;
        negative = 1'b0;
        hex_mode = 1'b1;
        get_frame(b_c1, b_c2, b_d0, b_d1, b_d2, b_d3, b_ct);
        $display("  Recibido: D0=0x%02X, D1=0x%02X, D2=0x%02X, D3=0x%02X", b_d0, b_d1, b_d2, b_d3);
        if (b_d0 === 8'h00 && b_d1 === 8'h00 && b_d2 === 8'h77 && b_d3 === 8'h6D)
            $display("  OK: Digitos corresponden a '  A5'");
        else
            $fatal(1, "ERROR: esperado 00 00 77 6D, obtenido %02X %02X %02X %02X", b_d0, b_d1, b_d2, b_d3);

        $display("\n==================================================");
        $display("TODAS LAS PRUEBAS DEL TM1637 PASARON SATISFACTORIAMENTE!");
        $display("==================================================");

        #1000;
        $finish;
    end

endmodule
