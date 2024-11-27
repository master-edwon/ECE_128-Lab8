`timescale 1ns / 1ps

module UP_Counter_tb();
    
    reg clk;          
    reg rst_n;        
    wire [11:0] count; 
    
    UP_Counter uut1 (clk,rst_n,count);
    
    always begin
        #1 clk = ~clk; 
    end
 
    initial begin
        clk = 0;
        rst_n = 0;
        #10 rst_n = 1;     
        // Let the counter run for some cycles
        #10000000;
        $stop;
    end

endmodule
