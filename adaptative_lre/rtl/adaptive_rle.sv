
module adaptive_rle #(
    parameter NB_DATA   = 8, 
    parameter NB_COUNT  = 8     
)(


    // Output
    output wire [NB_DATA -1:0] o_data  , // Símbolo comprimido
    output wire                o_valid ,
    output wire                o_start ,

    // Input
    input  wire [NB_DATA -1:0] i_data  ,
    input  wire                i_valid ,

    // Control
    output wire                o_last  ,
    output wire                o_ready ,
    input  wire                i_last  ,
    input  wire                i_ready ,

    // Clock and reset
    input  wire                i_clock ,
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
    wire                fifo_data_full      ;

    // Fifo marker
    wire [NB_COUNT-1:0] fifo_marker         ;
    wire                fifo_marker_empty   ;
    wire                fifo_marker_rd      ;
    wire                fifo_marker_full    ;

    // Encoder
    wire [NB_DATA -1:0] encoder_data          ;
    wire                encoder_valid         ;
    wire                encoder_start         ;
    wire                encoder_last          ;

    adaptive_rle_comparator #(
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
        .i_valid               (i_valid & o_ready        ),
        .i_last                (i_last                   ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );


    adaptive_rle_counter #   (
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


    adaptive_rle_fifo 
    #                          (
        .NB_DATA               (NB_DATA                  ),
        .NB_POINTER            (NB_FIFO_POINTER          )
    )
    u_fifo_data (
        .o_rd_data             (fifo_data                ),
        .o_level               (/*unconnected*/          ),
        .o_full                (fifo_data_full           ),
        .o_empty               (/*unconnected*/          ),
        .i_wr_data             (counter_data             ),
        .i_wr_valid            (counter_data_valid       ),
        .i_rd_valid            (fifo_data_rd             ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );


    adaptive_rle_fifo 
    #(
        .NB_DATA               (NB_COUNT                 ),
        .NB_POINTER            (NB_FIFO_POINTER -2       )
    )
    u_fifo_marker (
        .o_rd_data             (fifo_marker              ),
        .o_level               (                         ),
        .o_full                (fifo_marker_full         ),
        .o_empty               (fifo_marker_empty        ),
        .i_wr_data             (counter_marker           ),
        .i_wr_valid            (counter_marker_valid     ),
        .i_rd_valid            (fifo_marker_rd           ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );


    adaptive_rle_encoder 
    #(
        .NB_DATA               (NB_DATA                  ),
        .NB_COUNT              (NB_COUNT                 )
    )
    u_encoder (
        .o_data                (encoder_data             ),
        .o_valid               (encoder_valid            ),
        .o_start               (encoder_start            ),
        .o_last                (encoder_last             ),
        .o_fifo_data_rd        (fifo_data_rd             ),
        .o_fifo_marker_rd      (fifo_marker_rd           ),
        .i_fifo_empty          (fifo_marker_empty        ),
        .i_data                (fifo_data                ),
        .i_marker              (fifo_marker              ),
        .i_last                (counter_last             ),
        .i_clock               (i_clock                  ),
        .i_reset_n             (i_reset_n                )
    );

    assign o_data   = encoder_data  ;
    assign o_valid  = encoder_valid ;
    assign o_start  = encoder_start ;
    assign o_last   = encoder_last  ;
    assign o_ready = ~(fifo_data_full | fifo_marker_full);

endmodule