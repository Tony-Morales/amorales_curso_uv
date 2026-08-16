`timescale 1ns / 1ps

module tb_adaptive_lre;

    // ---------------------------------------
    // ---  Signals and variables          ---
    // ---------------------------------------

    `ifndef DEF_NB_DATA
        `define DEF_NB_DATA 8
    `endif

    `ifndef DEF_NB_COUNT
        `define DEF_NB_COUNT 8
    `endif

    // Parameters
    parameter NB_DATA    = `DEF_NB_DATA;
    parameter NB_COUNT   = `DEF_NB_COUNT;
    parameter CLK_PERIOD = 10; // 10ns clock period (100 MHz)

    // TB clock and reset
    reg                   tb_clock;
    reg                   tb_reset_n;

    // Data input
    reg  [NB_DATA-1:0]    tb_i_data;
    reg                   tb_i_valid;
    reg                   tb_i_last;
    reg                   tb_i_ready;

    // Data output
    wire [NB_DATA-1:0]    dut_data;
    wire                  dut_valid;
    wire                  dut_start;
    wire                  dut_last;
    wire                  dut_ready;

    // Files
    integer               fd_in;
    integer               fd_out_raw;
    integer               fd_out_decode;
    integer               scan_file;
    integer               current_data;
    integer               next_data;

    integer               fd_cmp_in;
    integer               fd_cmp_out_decode;
    integer               scan_in;
    integer               scan_out;
    integer               val_in;
    integer               val_out;
    integer               error_count;
    integer               line_num;

    // Decoder
    localparam STATE_WAIT_HDR = 0;
    localparam STATE_WAIT_RUN = 1;
    localparam STATE_WAIT_LIT = 2;

    integer               decode_state = 0;
    integer               decode_count = 0;
    integer               i;


    // ---------------------------------------
    // ---  TOP                            ---
    // ---------------------------------------

    adaptive_lre #(
        .NB_DATA  (NB_DATA),
        .NB_COUNT (NB_COUNT)
    ) u_dut (
        .o_data    (dut_data),
        .o_valid   (dut_valid),
        .o_start   (dut_start),
        .i_data    (tb_i_data),
        .i_valid   (tb_i_valid),
        .o_last    (dut_last),
        .o_ready   (dut_ready),
        .i_last    (tb_i_last),
        .i_ready   (tb_i_ready),
        .i_clock   (tb_clock),
        .i_reset_n (tb_reset_n)
    );

    // ---------------------------------------
    // ---  Clock generation               ---
    // ---------------------------------------

    initial begin
        tb_clock = 1'b0;
        forever #(CLK_PERIOD / 2) tb_clock = ~tb_clock;
    end

    // ---------------------------------------
    // ---  Send bytes to top module       ---
    // ---------------------------------------
    task send_byte(
        input [NB_DATA-1:0] data_to_send,
        input               is_last
    );
        begin
            tb_i_data  <= data_to_send;
            tb_i_valid <= 1'b1;
            tb_i_last  <= is_last;

            // Wait o_ready
            do begin
                @(posedge tb_clock);
            end while (!dut_ready);

            tb_i_valid <= 1'b0;
            tb_i_last  <= 1'b0;
        end
    endtask

    task drive_from_file();
        fd_in  = $fopen("input.txt", "r");
        if (fd_in == 0) begin
            $display("ERROR: can't open file.");
            $finish;
        end

        scan_file = $fscanf(fd_in, "%h\n", current_data);
        
        while (scan_file == 1) begin
            scan_file = $fscanf(fd_in, "%h\n", next_data);
            if (scan_file != 1) begin
                // Last data
                send_byte(current_data[NB_DATA-1:0], 1'b1);
            end else begin
                send_byte(current_data[NB_DATA-1:0], 1'b0);
                current_data = next_data;
            end
        end

        // Wait for the last data
        wait (dut_valid && dut_last && tb_i_ready);
        #(CLK_PERIOD * 10);
        $fclose(fd_in);
    endtask

    task check_data();
        fd_cmp_in  = $fopen("input.txt", "r");
        fd_cmp_out_decode = $fopen("result.txt", "r");
        error_count = 0;

        if (fd_cmp_in == 0 || fd_cmp_out_decode == 0) begin
            $display("ERROR: can't open file.");
        end else begin
            
            scan_in  = $fscanf(fd_cmp_in, "%h\n", val_in);
            scan_out = $fscanf(fd_cmp_out_decode, "%h\n", val_out);
            
            while (scan_in == 1) begin
                // Input file has more data than decoded output file
                if (scan_out != 1) begin
                    $display("WARNING: Decoded output file is shorter than input file");
                    error_count = error_count + 1;
                    break;
                end
                
                if (val_in !== val_out) begin
                    // $display("Mismatch in line %0d:  %02h, %02h", line_num, val_in, val_out);
                    error_count = error_count + 1;
                end
                
                line_num = line_num + 1;
                scan_in  = $fscanf(fd_cmp_in, "%h\n", val_in);
                scan_out = $fscanf(fd_cmp_out_decode, "%h\n", val_out);
            end
            
            if (scan_out == 1) begin
                $display("WARNING: Decoded output file is longer than input file");
                 error_count = error_count + 1;
            end
            
            $fclose(fd_cmp_in);
            $fclose(fd_cmp_out_decode);
            
            $display("\n\n--------------------------------------------------");
            if (error_count == 0) begin
                $display("PASS");
            end else begin
                $display("ERROR: %0d", error_count);
            end
            $display("--------------------------------------------------");
        end
    endtask

    task reset();
        tb_reset_n = 1'b0;
        #(CLK_PERIOD * 3);
        tb_reset_n = 1'b1;
        #(CLK_PERIOD/2);
        @(posedge tb_clock);
    endtask

    // ---------------------------------------
    // ---  Monitor - Decoder              ---
    // ---------------------------------------
    always @(posedge tb_clock) begin
        if (dut_valid && tb_i_ready) begin
            
            // If dut_start is 1, a marker/header is received
            $fdisplay(fd_out_raw, "%02H", dut_data);
            if(dut_start) begin
                $display("[TB Output @ %0t ns] Marker = %0d | Start = %0b ---------------------------", 
                    $time, $signed(dut_data), dut_start);
                
                decode_count = $signed(dut_data);
                
                if (decode_count > 0) begin
                    // Run mode
                    decode_state = STATE_WAIT_RUN;
                end else if (decode_count < 0) begin
                    // Literal mode
                    decode_state = STATE_WAIT_LIT;
                    decode_count = -decode_count;
                end
                
            end else begin
                $display("[TB Output @ %0t ns] Symbol = 0x%0H | Last = %0b", 
                        $time, dut_data, dut_last);
                
                // Run mode: Repeat symbol
                if (decode_state == STATE_WAIT_RUN) begin
                    for (i = 0; i < decode_count; i = i + 1) begin
                        $fdisplay(fd_out_decode, "%02H", dut_data);
                    end
                    decode_state = STATE_WAIT_HDR;
                    
                // Literal mode: Don't repeat symbol
                end else if (decode_state == STATE_WAIT_LIT) begin
                    $fdisplay(fd_out_decode, "%02H", dut_data);
                    decode_count = decode_count - 1;
                    
                    if (decode_count == 0) begin
                        decode_state = STATE_WAIT_HDR;
                    end
                end else begin
                    $display("Error");
                end
            end
        end
    end

    // ---------------------------------------
    // ---  Driver                         ---
    // ---------------------------------------
    initial begin
        tb_reset_n = 1'b0;
        tb_i_valid = 1'b0;
        tb_i_last  = 1'b0;
        tb_i_data  = {NB_DATA{1'b0}};
        tb_i_ready = 1'b1;

        $display("NB_DATA : ", NB_DATA );
        $display("NB_COUNT: ", NB_COUNT);

        $display("--------------------------------------------------");
        $display("---------------    Start test      ---------------");
        $display("--------------------------------------------------");

        fd_out_decode = $fopen("result.txt", "w");
        fd_out_raw    = $fopen("result_raw.txt", "w");

        // Reset
        reset();

        // Drive data
        drive_from_file();

        $fclose(fd_out_decode);
        $fclose(fd_out_raw   );

        $display("--------------------------------------------------");
        $display("---------------    Start Check     ---------------");
        $display("--------------------------------------------------");

        check_data();

        $finish;
    end

endmodule