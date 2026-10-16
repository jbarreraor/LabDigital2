module alu (
    input  wire [3:0] operand_a,
    input  wire [3:0] operand_b,
    input  wire [2:0] operation,

    output reg  [7:0] result,    // 8 bits porque 15*15 = 225
    output wire       negative   // 1 solo si la operación es resta y el resultado es negativo
);

always @(*) begin
    case (operation)

        3'b000: result = operand_a + operand_b;                          // Suma
        3'b001: result = {4'b0000, operand_a} - {4'b0000, operand_b};    // Resta
        3'b010: result = operand_a * operand_b;                          // Multiplicación

        3'b011: begin                                                    // Módulo
            if (operand_b != 0)
                result = operand_a % operand_b;
            else
                result = 8'b0;
        end

        3'b100: result = {4'b0000, (operand_a & operand_b)};             // AND
        3'b101: result = {4'b0000, (operand_a | operand_b)};             // OR
        3'b110: result = {4'b0000, (operand_a ^ operand_b)};             // XOR

        default: result = 8'b0;                                          // Código 111 sin uso

    endcase
end

// El bit 7 solo indica negativo cuando la operación es resta
assign negative = (operation == 3'b001) && result[7];

endmodule