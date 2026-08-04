
module adaptive_lre #(
    parameter NB_DATA   = 8,     // Ancho de bits del símbolo de entrada
    parameter NB_COUNT  = 8      // Ancho de bits del contador de longitud/racha
)(

    // ---------------------------------------
    // ---      Canal de entrada          ---
    // ---------------------------------------
    input  wire [NB_DATA -1:0] i_data ,
    input  wire                i_valid,
    input  wire                i_last , // Indica fin del bloque/paquete
    output wire                o_ready,

    // ---------------------------------------
    // ---      Canal de salida            ---
    // ---------------------------------------
    output wire [NB_DATA -1:0] o_data , // Símbolo comprimido
    output wire [NB_COUNT-1:0] o_count, // Longitud de la racha
    output wire                o_valid,
    output wire                o_last ,
    input  wire                i_ready,

    // ---------------------------------------
    // ---      Control / Configuración    ---
    // ---------------------------------------
    input  wire                i_clear, // Reinicia el historial adaptativo
    output wire                o_busy ,

    // ---------------------------------------
    // --- Reloj y Reseteo ---
    // ---------------------------------------
    input  wire                i_clock,
    input  wire                i_reset_n
);


    wire [NB_DATA -1:0] comp_data;
    wire                comp_valid;
    wire                comp_mode;
    wire                comp_emit;


    adaptative_lre_comparator #(
        .NB_DATA  (NB_DATA)
    ) u_look_ahead_comparator (
        .i_data        (i_data),
        .i_valid       (i_valid),
        .i_last        (i_last),
        .o_data        (comp_data),
        .o_valid       (comp_valid),
        .o_mode        (comp_mode),
        .o_start_mode  (comp_start_mode),
        .i_clock       (i_clock),
        .i_reset_n     (i_reset_n)
    );


    adaptative_lre_counter #(
        .NB_DATA  (NB_DATA),
        .NB_COUNT (NB_COUNT)
    ) u_counter (
        .i_data    (comp_data),
        .i_valid   (comp_valid),
        .i_last    (i_last),
        .i_mode    (comp_mode), // Conectado al comparador
        .i_start_mode (comp_start_mode), // Conectado al comparador
        .o_data    (),
        .o_count   (),
        .o_valid   (),
        .o_end_count    (),
        .i_clock   (i_clock),
        .i_reset_n (i_reset_n)
    );




endmodule