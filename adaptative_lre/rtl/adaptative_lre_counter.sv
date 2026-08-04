module adaptative_lre_counter #(
    parameter NB_DATA   = 8,     // Ancho de bits del símbolo de entrada
    parameter NB_COUNT  = 8      // Ancho de bits del contador de longitud/racha
) (
    
    // ---------------------------------------
    // ---      Canal de entrada          ---
    // ---------------------------------------
    input  wire [NB_DATA -1:0] i_data ,
    input  wire                i_valid,
    input  wire                i_last , // Indica fin del bloque/paquete
    input  wire                i_emit,  // Señal de corte desde el comparador
    input  wire                i_mode,  // NUEVO: 1 = run_mode | 0 = literal_mode

    // ---------------------------------------
    // ---      Canal de salida            ---
    // ---------------------------------------
    output wire [NB_DATA -1:0] o_data , // Símbolo emitido
    output wire [NB_COUNT-1:0] o_count, // Longitud de la racha acumulada
    output wire                o_valid, // Alto solo cuando se emite un paquete
    output wire                o_emit,  // Reflejo del evento de emisión

    // ---------------------------------------
    // --- Reloj y Reseteo ---
    // ---------------------------------------
    input  wire                i_clock,
    input  wire                i_reset_n
);

    localparam N_STAGE = 2;
    // Registros y cables internos
    reg  signed [NB_COUNT-1:0] count;
    wire signed [NB_COUNT-1:0] next_count;
    wire signed [NB_COUNT-1:0] incr_sel;
    wire                       min_count;
    wire                       max_count;
    wire                       limit_count;
    wire                       emit;

    wire start_run;
    wire start_literal;

    // Registros de salida (para no tener lógica combinacional larga)
    reg [N_STAGE-1:0] [NB_DATA -1:0] data_d;
    reg [NB_COUNT-1:0] count_d;
    reg [N_STAGE -1:0]valid_d;
    reg                emit_d;
    reg                emit_out;




    // ---------------------------------------
    // ---  Emit Logic                     ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if(~i_reset_n) begin
            emit_d <= 0;
        end else begin
            emit_d <= i_emit;
        end
    end

    assign start_run     = ~i_mode & i_emit & i_valid;
    assign start_literal = ~i_mode & emit_d & i_valid;
    assign emit = (start_run | start_literal | limit_count| i_last);

    // ---------------------------------------
    // ---  Count Logic                    ---
    // ---------------------------------------

    assign incr_sel   = i_mode ? 1 : -1;
    assign next_count = count + incr_sel;

    assign max_count = (~next_count[NB_COUNT-1]) & (&next_count[NB_COUNT-2:0]);
    assign min_count =  (next_count[NB_COUNT-1]) & (~(|next_count[NB_COUNT-2:0]));
    assign limit_count = i_valid & (max_count | min_count);

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            count <= 0;
        end else if (start_run) begin
            count <= 1; 
        end else if(start_literal) begin
            count <= -1; 
        end else if(i_valid)begin
            count <= next_count;
        end
    end

    // ---------------------------------------
    // ---  Output Assign Logic            ---
    // --------------------------------------- 
    
    // Registramos la salida para alinearla con el reloj y evitar glitches
    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            valid_d <= 0;
        end else begin
            valid_d[0] <= i_valid;
            valid_d[1] <= valid_d[0];
        end 
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            count_d <= 0;
        end if (emit) begin
            count_d <= count;
        end
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            data_d  <= 0;
        end if(i_valid) begin
            data_d[0]  <= i_data;
            data_d[1]  <= data_d[0];
        end
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            emit_out  <= 0;
        end begin
            emit_out  <= emit;
        end
    end

    // Asignación final a los puertos
    assign o_data  = data_d[1];
    assign o_count = count_d;
    assign o_valid = valid_d[1];
    assign o_emit  = emit_out;

endmodule