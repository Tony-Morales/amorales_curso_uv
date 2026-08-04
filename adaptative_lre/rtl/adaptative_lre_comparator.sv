module adaptative_lre_comparator #(
    parameter NB_DATA   = 8     // Ancho de bits del símbolo de entrada
) (
    
    // ---------------------------------------
    // ---      Canal de entrada          ---
    // ---------------------------------------
    input  wire [NB_DATA -1:0] i_data ,
    input  wire                i_valid,
    input  wire                i_last , // Indica fin del bloque/paquete

    // ---------------------------------------
    // ---      Canal de salida            ---
    // ---------------------------------------
    output wire [NB_DATA -1:0] o_data , // Símbolo comprimido
    output wire                o_valid,
    output wire                o_mode, // 1 = run_mode | 0 = literal_mode
    output wire                o_emit,

    // ---------------------------------------
    // --- Reloj y Reseteo ---
    // ---------------------------------------
    input  wire                i_clock,
    input  wire                i_reset_n
);

    reg  [NB_DATA -1:0]  ref_data;
    reg  [NB_DATA -1:0]  ref_data_d;
    reg  [2-1:0]  valid_sr;
    wire match_prev;
    wire match_next;

    reg mode;
    reg emit;


    reg mode_filter;
    reg emit_filter;

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            ref_data  <= 0;
            ref_data_d <= 0;
            valid_sr <= 0;
        end else if (i_valid) begin
            ref_data  <= i_data;
            ref_data_d <= ref_data;
            valid_sr <= {valid_sr[0], 1'b1};
        end
    end

    assign match_prev = (ref_data_d == ref_data);
    assign match_next = (ref_data   == i_data  );

    always @(*) begin
        case ({match_prev, match_next})
            2'b11: begin
                mode = 1'b1;
                emit = 1'b0;
            end
            2'b10: begin
                mode = 1'b1;
                emit = 1'b1;
            end
            2'b01: begin
                mode = 1'b0;
                emit = 1'b1;
            end
            2'b00: begin
                mode = 1'b0;
                emit = 1'b0;
            end
            default: begin
                mode = 1'b0;
                emit = 1'b0;
            end
        endcase
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            mode_filter <= 0;
            emit_filter <= 0;
        end else if(i_valid) begin
            mode_filter <= mode;
            emit_filter <= emit;
        end
    end



    assign o_data = ref_data_d;
    assign o_valid = valid_sr[1] & i_valid;
    assign o_mode = mode_filter;
    assign o_emit = emit_filter;

endmodule