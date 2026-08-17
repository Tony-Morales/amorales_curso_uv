module adaptive_rle_fifo #(
    parameter NB_DATA    = 8,
    parameter NB_POINTER = 4 
) (
    // Output
    output wire [NB_DATA -1:0] o_rd_data ,
    output wire [NB_POINTER:0] o_level   ,
    output wire                o_full    ,
    output wire                o_empty   ,

    // Input
    input  wire [NB_DATA -1:0] i_wr_data ,
    input  wire                i_wr_valid,
    input  wire                i_rd_valid,

    // Clock and reset
    input  wire                i_clock   ,
    input  wire                i_reset_n
);

    localparam DEPTH = 1 << NB_POINTER; // 2^NB_POINTER

    // memory and pointer signals
    reg [NB_DATA   -1:0]    mem [0:DEPTH-1];
    reg [NB_POINTER-1:0]    wr_ptr         ;
    reg [NB_POINTER-1:0]    rd_ptr         ;
    reg [NB_POINTER  :0]    level          ;

    // Control signals
    wire                    wr_en          ;
    wire                    rd_en          ;
    wire                    full           ;
    wire                    empty          ;
    wire                    overflow       ;

    // ---------------------------------------
    // ---  Control logic                  ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            level <= 0;
        end else begin
            case ({wr_en, rd_en})
                2'b10: level <= level + 1'b1; // write
                2'b01: level <= level - 1'b1; // read
                default: level <= level; 
            endcase
        end
    end

    assign empty = (level == 0);
    assign full  = (level == DEPTH);
    assign overflow = i_wr_valid & full;

    assign wr_en = i_wr_valid & ~full;
    assign rd_en = i_rd_valid & ~empty;

    // ---------------------------------------
    // ---   Pointer Logic                 ---
    // ---------------------------------------

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            wr_ptr <= 0;
        end else if (wr_en) begin
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    always @(posedge i_clock or negedge i_reset_n) begin
        if (~i_reset_n) begin
            rd_ptr <= 0;
        end else if (rd_en) begin
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

    // ---------------------------------------
    // ---  Memory                         ---
    // ---------------------------------------

    always @(posedge i_clock) begin
        if (wr_en) begin
            mem[wr_ptr] <= i_wr_data;
        end
    end

    // ---------------------------------------
    // ---  Output Assign                  ---
    // ---------------------------------------

    assign o_rd_data  = mem[rd_ptr];
    assign o_level    = level      ;
    assign o_empty    = empty      ;
    assign o_full     = full       ;

endmodule