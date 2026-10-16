
module reg_bank (
    input wire clk,
    input wire write_enable, //Con esto activo/desactivo la escritura

    input wire [1:0] write_addr, //Elijo en qué registro escribir
    input wire [3:0] write_data, //Dato a guardar en el registro seleccionado

    input wire [1:0] read_addr_a, //Elijo qué registro leer A
    output wire [3:0] read_data_a, //Dato leído del registro seleccionado A

    input wire [1:0] read_addr_b, //Elijo qué registro leer B
    output wire [3:0] read_data_b //Dato leído del registro seleccionado B
);

    // 4 registros de 4 bits
    reg [3:0] registers [0:3];

    //Para que en la simulación no me tire errores.
    initial begin
        registers[0] = 4'b0000; //R0
        registers[1] = 4'b0000; //R1
        registers[2] = 4'b0000; //R2
        registers[3] = 4'b0000; //R3
    end

    // Escritura síncrona
    always @(posedge clk) begin
        if (write_enable) begin
            registers[write_addr] <= write_data;
        end
    end

    // Lectura asíncrona
    assign read_data_a = registers[read_addr_a];
    assign read_data_b = registers[read_addr_b];


endmodule
