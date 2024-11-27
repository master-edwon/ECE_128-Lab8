`timescale 1ns / 1ps

module UP_Counter (
    input clk,         
    input rstn,       
    output reg [11:0] count 
);
    
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            count <= 12'b000000000000; // Reset the counter to 0
        else 
            count <= count + 1; // Increment the counter on every clock cycle
    end

endmodule
