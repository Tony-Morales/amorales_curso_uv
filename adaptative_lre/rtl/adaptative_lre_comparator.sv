module adaptative_lre_comparator #(
    parameter NB_DATA   = 8
) (
    // Outputs
    output wire [NB_DATA -1:0] o_data      ,
    output wire                o_valid     ,
    output wire                o_mode      ,
    output wire                o_start_mode,

    // Inputs
    input  wire [NB_DATA -1:0] i_data      ,
    input  wire                i_valid     ,
    input  wire                i_last      ,

    // Clock and reset
    input  wire                i_clock     ,
    input  wire                i_reset_n
);
    localparam N_STAGE = 2;


    // Buffer registers
    reg  [NB_DATA -1:0] ref_data;
    reg  [NB_DATA -1:0] ref_data_d;
    reg  [N_STAGE -1:0] valid_sr;

    // Match signals
    wire                match_prev;
    wire                match_next;

    reg                 mode;
    reg                 emit;


    reg                 mode_filter;
    reg                 emit_filter;

    reg                 emit_d;
    wire                start_run;
    wire                start_literal;
    wire valid;

    // ---------------------------------------
    // ---  Input Buffer                   ---
    // ---------------------------------------
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

    // ---------------------------------------
    // ---  Match logic                    ---
    // ---------------------------------------

    assign match_prev = (ref_data_d == ref_data);
    assign match_next = (ref_data   == i_data  );

    // ---------------------------------------
    // ---  Match decoder                  ---
    // ---------------------------------------
    // | match_prev | match_next | mode | emit |
    // |------------|------------|------|------|
    // |     0      |     0      |  0   |  0   |
    // |     0      |     1      |  0   |  1   |
    // |     1      |     0      |  1   |  1   |
    // |     1      |     1      |  1   |  0   |

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

    // ---------------------------------------
    // ---  Control  Logic                 ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if(~i_reset_n) begin
            emit_d <= 0;
        end else begin
            emit_d <= emit_filter;
        end
    end

    assign valid         = valid_sr[1] & i_valid;
    assign start_run     = ~mode_filter & emit_filter & valid;
    assign start_literal = ~mode_filter & emit_d & valid;

    // ---------------------------------------
    // ---  Output Assign                  ---
    // ---------------------------------------

    assign o_data       = ref_data_d;
    assign o_valid      = valid;
    assign o_mode       = start_run | mode_filter;
    assign o_start_mode = start_run | start_literal;

endmodule