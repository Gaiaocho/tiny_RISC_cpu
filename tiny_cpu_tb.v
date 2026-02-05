`timescale 1ns / 1ps

module tiny_cpu_tb;

  // Clock and DUT signals
  reg CLK = 0;
  wire led_red, led_green, led_blue;


  // Instantiate the tiny_cpu
  tiny_cpu dut (
      .CLK      (CLK),
      .led_red  (led_red),
      .led_green(led_green),
      .led_blue (led_blue)
  );

  // Generate clock (adjust period as needed)
  always #10 CLK = ~CLK;  // 50 MHz clock

  // Track register values for verification
  integer cycle_count = 0;
  integer error_count = 0;
  integer slow_clock_cycles = 0;


  /*
   *  These are placeholder instructions before we have to deal with
   *  a compiler.
   *  The lower 4 bits now become the register to use
   */
  initial begin
    dut.ROM[0]  = 32'h00500093;  // ADDI x1, x0, 5
    dut.ROM[1]  = 32'h00300113;  // ADD1 x1, x2, 3
    dut.ROM[2]  = 32'h002081B3;  // ADD x3, x1,  8
    dut.ROM[3]  = 32'h0071F213;  // ANDI x4, x3, 0
    dut.ROM[4]  = 32'h0011E293;  // ORI  x5, x3, 9
    dut.ROM[5]  = 32'h02A00313;  // ADDI x6, x0, 42
    dut.ROM[6]  = 32'h00000393;  // ADDI x7, x0, 0
    dut.ROM[7]  = 32'h00638023;  // SW   x6, 0(x7)
    dut.ROM[8]  = 32'h00000000;
    dut.ROM[9]  = 32'h0003A403;  // LW   x8, 0(x7)
    dut.ROM[10] = 32'h00000000;
    dut.ROM[11] = 32'h00000000;
    dut.ROM[12] = 32'h00000000;
    dut.ROM[13] = 32'h00000000;
    dut.ROM[14] = 32'h00000000;
    dut.ROM[15] = 32'h00000000;
  end

  initial begin
    $dumpvars(0, tiny_cpu_tb);  // Dump all variables for waveform viewing

    // Wait for initial values to settle
    #100;

    // Monitor the execution for a number of slow clock cycles
    for (
        slow_clock_cycles = 0; slow_clock_cycles < 20; slow_clock_cycles = slow_clock_cycles + 1
    ) begin
      // Wait for a rising edge of the slow clock
      @(posedge dut.slow_clk);

      $display("Slow cycle %0d: PC=%0d, IR=%h, LEDs: R=%b, G=%b, B=%b", slow_clock_cycles, dut.PC,
               dut.IR, led_red, led_green, led_blue);

      // Display register values
      if (slow_clock_cycles > 0) begin
        $display("  Registers: x1=%h, x2=%h, x3=%h, x4=%h, x5=%h", dut.R[1], dut.R[2], dut.R[3],
                 dut.R[4], dut.R[5]);
      end
    end

    // Final verification
    $display("\n=== Final Results ===");
    $display("x1 (should be 5): %h", dut.R[1]);
    $display("x2 (should be 3): %h", dut.R[2]);
    $display("x3 (should be 8): %h", dut.R[3]);  // 5 + 3 = 8
    $display("x4 (should be 0): %h", dut.R[4]);
    $display("x5 (should be 9): %h", dut.R[5]);

    // Test LType & SType
    $display("x6 (after SW/LW should be 2A/42): %h", dut.R[6]);
    $display("x7 (base address, should be 0): %h", dut.R[7]);
    $display("RAM[0]( should be 2a): %h", dut.RAM[0]);
    $display("x8 (load value, should be 2a): %h", dut.R[8]);




    // Verify expected results
    assert (dut.R[1] === 32'h5)
    else begin
      error_count++;
      $error("x1 should be 5, got %h", dut.R[1]);
    end

    assert (dut.R[2] === 32'h3)
    else begin
      error_count++;
      $error("x2 should be 3, got %h", dut.R[2]);
    end

    assert (dut.R[3] === 32'h8)
    else begin
      error_count++;
      $error("x3 should be 8, got %h", dut.R[3]);
    end

    // STYPE & LTYPE

    assert (dut.R[6] === 32'h2A)
    else begin
      error_count++;
      $error("x6 should be 2A/42, got %h", dut.R[6]);
    end

    assert (dut.R[7] === 32'h0)
    else begin
      error_count++;
      $error("x7 should be 0, got %h", dut.R[7]);
    end

    assert (dut.RAM[0] === 32'h2A)
    else begin
      error_count++;
      $error("RAM[0] should be 2A/42, got %h", dut.RAM[0]);
    end

    assert (dut.R[8] === 32'h2A)
    else begin
      error_count++;
      $error("x8 should be 2a, got %h", dut.R[8]);
    end



    $display("\nTest completed with %0d errors", error_count);

    if (error_count == 0) begin
      $display("TEST PASSED!");
    end else begin
      $display("TEST FAILED!");
    end

    $finish;
  end

endmodule
