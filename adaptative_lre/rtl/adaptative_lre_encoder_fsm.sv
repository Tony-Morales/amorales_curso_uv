module adaptative_lre_encoder_fsm #(
    parameter NB_DATA  = 8,
    parameter NB_COUNT = 8
)  (
    output wire         o_data_sel    ,
    output wire         o_rd_count    ,
    output wire         o_rd_data     ,
    output wire         o_reset_count ,
    output wire         o_last        ,


    input  wire         i_fifo_empty  ,
    input  wire         i_mode        ,
    input  wire         i_count_reach ,
    input  wire         i_last        ,

    input  wire         i_clock       ,
    input  wire         i_reset_n
);
    localparam NB_STATE = 3;

    typedef enum reg [NB_STATE-1:0] {
        STATE_IDLE        = 0,
        STATE_READ_COUNT  = 1,
        STATE_SEND_COUNT  = 2,
        STATE_SEND_LIT    = 3,
        STATE_SEND_RUN    = 4,
        STATE_CHECK_FIFO  = 5
     } fsm_state_t;

    fsm_state_t state      ;
    fsm_state_t next_state ;

    reg         rd_data    ;
    reg         rd_count   ;
    reg         reset_count;
    reg         data_sel   ;

    reg         last_flag  ;
    wire        last       ;

    // ---------------------------------------
    // ---  Last control                   ---
    // ---------------------------------------
    assign last = next_state == STATE_CHECK_FIFO & i_fifo_empty & last_flag;

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n | last) begin
            last_flag  <= 1'b0;
        end else if (i_last) begin
            last_flag  <= 1'b1;
        end
    end

    //-----------------------------------------
    //---  State register                   ---
    //-----------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            state  <= STATE_IDLE;
        end else begin
            state  <= next_state;
        end
    end

    //-----------------------------------------
    //---  State selection                  ---
    //-----------------------------------------

    always @(*) begin
        next_state = state;

        case (state)
            STATE_IDLE: begin
                if (~i_fifo_empty) begin
                    next_state = STATE_READ_COUNT;
                end
            end
            
            STATE_READ_COUNT: begin
                next_state = STATE_SEND_COUNT;
            end
            STATE_SEND_COUNT: begin
                if (i_mode) begin
                    next_state = STATE_SEND_RUN;
                end else begin
                    next_state = STATE_SEND_LIT;
                end
            end
            
            STATE_SEND_LIT: begin
                if(i_count_reach) begin
                    next_state = STATE_CHECK_FIFO;
                end
            end

            STATE_SEND_RUN: begin
                next_state = STATE_CHECK_FIFO;
            end

            STATE_CHECK_FIFO: begin
                if(i_fifo_empty) begin
                    next_state = STATE_IDLE;
                end else begin
                    next_state = STATE_READ_COUNT;
                end
            end
            
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    //-----------------------------------------
    //---  Output selection                 ---
    //-----------------------------------------

    always @(*) begin
        case (state)
            STATE_IDLE: begin
                rd_count    = 1'b0;
                rd_data     = 1'b0;
                reset_count = 1'b1;
                data_sel    = 1'b0;
            end

            STATE_READ_COUNT: begin
                rd_count    = 1'b1;
                rd_data     = 1'b0;
                reset_count = 1'b1;
                data_sel    = 1'b0;
            end

            STATE_SEND_COUNT: begin
                rd_count    = 1'b0;
                rd_data     = 1'b1;
                reset_count = 1'b0;
                data_sel    = 1'b1;
            end

            STATE_SEND_LIT: begin
                rd_count    = 1'b0;
                rd_data     = 1'b1;
                reset_count = 1'b0;
                data_sel    = 1'b0;
            end

            STATE_SEND_RUN: begin
                rd_count    = 1'b0;
                rd_data     = 1'b0;
                reset_count = 1'b0;
                data_sel    = 1'b0;
            end

            STATE_CHECK_FIFO: begin
                rd_count    = 1'b0;
                rd_data     = 1'b0;
                reset_count = 1'b1;
                data_sel    = 1'b0;
            end

            default: begin
                rd_count    = 1'b0;
                rd_data     = 1'b0;
                reset_count = 1'b1;
                data_sel    = 1'b0;
            end

        endcase
    end

    //-----------------------------------------
    //---  Output assign                    ---
    //-----------------------------------------

    assign o_rd_count    = rd_count   ;
    assign o_rd_data     = rd_data    ;
    assign o_reset_count = reset_count;
    assign o_data_sel    = data_sel   ;
    assign o_last        = last       ;

endmodule