
module adaptive_lre #(
    parameter NB_DATA   = 8, 
    parameter NB_COUNT  = 8     
)(


    // Output
    output wire [NB_DATA -1:0] o_data , // Símbolo comprimido
    output wire [NB_COUNT-1:0] o_marker, // Longitud de la racha
    output wire                o_valid,
    output wire                o_start,

    // Input
    input  wire [NB_DATA -1:0] i_data ,
    input  wire                i_valid,

    // Control
    output wire                o_last ,
    output wire                o_ready,
    input  wire                i_ready,
    input  wire                i_last ,
    input  wire                i_stop ,

    // Clock and reset
    input  wire                i_clock,
    input  wire                i_reset_n
);


    localparam NB_FIFO_POINTER = NB_COUNT -1;

    // Comparator
    wire [NB_DATA -1:0] comp_data           ;
    wire                comp_valid          ;
    wire                comp_mode           ;
    wire                comp_last           ;

    // Counter
    wire [NB_DATA -1:0] counter_data        ;
    wire                counter_data_valid  ;
    wire [NB_COUNT-1:0] counter_marker      ;
    wire                counter_marker_valid;
    wire                counter_last        ;

    // Fifo data 
    wire [NB_DATA -1:0] fifo_data           ;
    wire                fifo_data_rd        ;

    // Fifo marker
    wire                fifo_marker_empty   ;
    wire                fifo_marker_rd      ;
    wire [NB_COUNT-1:0] fifo_marker         ;


    adaptative_lre_comparator #(
        .NB_DATA               (NB_DATA                  )
    ) 
    u_comparator 
    (
        .o_data                (comp_data                ),
        .o_valid               (comp_valid               ),
        .o_mode                (comp_mode                ),
        .o_start               (comp_start               ),
        .o_last                (comp_last                ),
        .i_data                (i_data                   ),
        .i_valid               (i_valid                  ),
        .i_last                (i_last                   ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );


    adaptative_lre_counter #   (
        .NB_DATA               (NB_DATA                  ),
        .NB_COUNT              (NB_COUNT                 )
    ) 
    u_counter (
        .o_data                (counter_data             ),
        .o_marker              (counter_marker           ),
        .o_valid               (counter_data_valid       ),
        .o_marker_valid        (counter_marker_valid     ),
        .o_last                (counter_last             ),
        .i_data                (comp_data                ),
        .i_valid               (comp_valid               ),
        .i_last                (comp_last                ),
        .i_mode                (comp_mode                ),
        .i_start               (comp_start               ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );


    adaptative_lre_fifo 
    #                          (
        .NB_DATA               (NB_DATA                  ),
        .NB_POINTER            (NB_FIFO_POINTER          )
    )
    u_fifo_data (
        .i_wr_data             (counter_data             ),
        .i_wr_valid            (counter_data_valid       ),
        .o_full                (/*unconnected*/          ),
        .o_rd_data             ( fifo_data               ),
        .i_rd_valid            ( fifo_data_rd            ),
        .o_empty               (/*unconnected*/          ),
        .o_level               (/*unconnected*/          ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );


    adaptative_lre_fifo 
    #(
        .NB_DATA               (NB_COUNT                 ),
        .NB_POINTER            (2                        )
    )
    u_fifo_marker (
        .i_wr_data             (counter_marker           ),
        .i_wr_valid            (counter_marker_valid     ),
        .o_full                (                         ),
        .o_rd_data             (fifo_marker              ),
        .i_rd_valid            (fifo_marker_rd           ),
        .o_empty               (fifo_marker_empty        ),
        .o_level               (                         ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );


    adaptative_lre_encoder 
    #(
        .NB_DATA               (NB_DATA                  ),
        .NB_COUNT              (NB_COUNT                 )
    )
    u_encoder (
        .o_data                (                         ),
        .o_valid               (                         ),
        .o_start               (                         ),
        .o_last                (                         ),
        .o_fifo_data_rd        (fifo_data_rd             ),
        .o_fifo_marker_rd      (fifo_marker_rd           ),
        .i_fifo_empty          (fifo_marker_empty        ),
        .i_data                (fifo_data                ),
        .i_marker              (fifo_marker              ),
        .i_last                (counter_last             ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );

endmodule