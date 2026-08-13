module adaptative_lre_encoder #(
    parameter NB_DATA  = 8,
    parameter NB_COUNT = 8
)  (
    // Output
    output wire [NB_DATA -1:0] o_data          ,
    output wire                o_valid         ,
    output wire                o_start         ,
    output wire                o_last          ,

    // FIFO control
    output wire                o_fifo_data_rd  ,
    output wire                o_fifo_marker_rd ,
    input  wire                i_fifo_empty    ,

    // FIFO data
    input wire [NB_DATA -1:0] i_data           ,
    input wire [NB_COUNT-1:0] i_marker         ,

    input wire                i_last           ,

    // Clock and reset
    input  wire                i_clock         ,
    input  wire                i_reset_n
);

    // Counter signals
    reg  signed [NB_COUNT-1 :0] marker_d       ;
    reg         [NB_COUNT-1:0]  word_count     ;
    wire        [NB_COUNT-1:0]  next_word_count;

    wire signed [NB_COUNT   :0] marker_abs     ;
    reg                         mode           ;

    // Data signals
    reg        [NB_DATA -1 :0] data_d          ;

    // Control signals
    wire                        data_sel       ;
    wire                        rd_count       ;
    wire                        rd_data        ;
    wire                        reset_count    ;
    wire                        count_reach    ;
    wire                        fsm_last       ;


    // ---------------------------------------
    // ---  Input registers                ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if(~i_reset_n) begin
            mode      <= 1'b0;
            marker_d <= 0;
        end else if(rd_count) begin
            mode     <= ~i_marker[NB_COUNT-1];
            marker_d <=  i_marker;
        end
    end

    assign marker_abs =  mode? marker_d : -marker_d;

    always @(posedge i_clock or negedge i_reset_n) begin
        if(~i_reset_n) begin
            data_d <= 0;
        end else if(rd_data) begin
            data_d <=  i_data;
        end
    end

    // ---------------------------------------
    // ---  Count Logic                    ---
    // ---------------------------------------

    assign next_word_count = word_count + 1;
    assign count_reach = next_word_count >= marker_abs[NB_COUNT-1:0];

    always @(posedge i_clock or negedge i_reset_n) begin
        if(i_reset_n == 1'b0 | reset_count) begin
            word_count <= 0;
        end else if (rd_data & (~mode)) begin
            word_count <= next_word_count;
        end
    end

    // ---------------------------------------
    // ---  FSM                            ---
    // ---------------------------------------

    adaptative_lre_encoder_fsm
    #(
        .NB_DATA                 (NB_DATA      ),
        .NB_COUNT                (NB_COUNT     )
    )
    u_encoder_fsm (
        .o_data_sel              (data_sel     ),
        .o_rd_count              (rd_count     ),
        .o_rd_data               (rd_data      ),
        .o_reset_count           (reset_count  ),
        .o_last                  (fsm_last     ),
        .i_fifo_empty            (i_fifo_empty ),
        .i_mode                  (mode         ),
        .i_count_reach           (count_reach  ),
        .i_last                  (i_last       ),
        .i_clock                 (i_clock      ),
        .i_reset_n               (i_reset_n    )
    );

    reg valid;
    always @(posedge i_clock or negedge i_reset_n) begin
        if(i_reset_n == 1'b0) begin
            valid <= 0;
        end else begin
            valid <= rd_count | rd_data;
        end
    end


// assign o_data           = data_sel? marker_d : data_d ;
assign o_data           = data_sel? {{(NB_DATA - NB_COUNT)  {marker_d[NB_COUNT-1]}}, marker_d} : data_d ;
assign o_valid          = valid;
assign o_start          = valid & data_sel;
assign o_fifo_marker_rd = rd_count;
assign o_fifo_data_rd   = rd_data;
assign o_last           = fsm_last;

endmodule