`timescale 1ns/10ps 
interface i2c_if #(int I2C_ADDR_WIDTH = 7, int I2C_DATA_WIDTH = 8)
(
    //system signals
    input logic rst_i,
    
    //slave signals
    input logic scl,
    inout triand sda
);

// variable declarations
bit start             = 1'd0;
bit stop              = 1'd1;
logic repeated_start    = 1'd0;

bit [I2C_ADDR_WIDTH-1:0] addr_in;

bit [I2C_DATA_WIDTH-1:0] data_in;
bit [I2C_DATA_WIDTH-1:0] data_o[];
bit [I2C_DATA_WIDTH-1:0] write_data_captured[];


bit sda_oe  = 1'b0;
logic sda_bit = 1'b0;
bit rw      = 1'd0;

int i = 0;
int byte_number = 0;

///////////////////////////////////////////
//capture start condition
task capture_start();

    @(negedge sda);

    if(scl == 1'd1)begin
        start = 1'd1;
        stop = 1'd0;
        repeated_start = 1'd0;  
    end   
    ASSERT_I2C_START: assert( start == 1'd1 )else begin
        $display("ASSERT_I2C_START: I2C start assert failed");
        $error;
    end
endtask

///////////////////////////////////////
task capture_addr();
    i=0;
    // $display("////////////// CAPTURE ADDRESS -- REACHED /////////////////////");
    // $display("DATA_WIDTH:%d", I2C_DATA_WIDTH);
    repeat(I2C_DATA_WIDTH)begin
            //$display("///// val if i:%d ///////", i);
        @(posedge scl);
        if(i < I2C_ADDR_WIDTH)begin 
            addr_in[I2C_ADDR_WIDTH-1-i] = sda;
            //$display("SDA VAL FOR ADDR: %01b", sda);
        end
        else begin 
            rw = sda; 
        end
        i=i+1;
        
        // $display("///////////////// ADDRESS CAPTURED //////////////");
        // $display("ADDR CAPTURED: %07b",addr_in );
        // $display("/////////////////////////////////////////////////");
        end

endtask

////////////////////////////////////////
// Assign the SDA line based on sda_oe
assign sda = (sda_oe) ? sda_bit : 1'bz;

task send_ack();
    @(posedge scl);
    sda_oe = 1'd1;
    ASSERT_send_ACK_1: assert(sda == 1'd1)
    else begin
        $display("SEND_ACK Failed");
        $error;
    end

    @(negedge scl);
    sda_oe = 1'b0;
    ASSERT_send_ACK_2: assert(sda == 1'd0)
    else begin
        $display("SEND_ACK Failed");
        $error;
    end
    // $display("/////////////////////////////////////////");
    // $display("SDA FLG: %d, SDA VAL: %01b",sda_oe, sda);
    // $display("/////////////////////////////////////////");
endtask

//////////////////////////////////////
task  get_write_data();
    i = I2C_DATA_WIDTH-1;
    repeat(I2C_DATA_WIDTH)begin
        @(posedge scl);
        data_in[i] = sda;
        i--;  
    end
    write_data_captured[byte_number]          = data_in;
    // $display("///////////////// WRITE DATA CAPTURED - 1 ///////////// ");
    // $display("            %d          ", write_data_captured[byte_number] );
    // $display("///////////////// /////////////////// ///////////// ");
endtask

/////////////////////////////////////
task capture_stop_repeated_start();
while(stop == 1'd0) begin
        //stop condition
        @(posedge sda);
        if(scl)begin          
            stop = 1'd1;
            start = 1'd0;
            repeated_start = 1'd0;
            break;            
        end
    //repeated start condition
//     @(negedge sda)begin
//         if(scl == 1'd1)begin
//             stop = 1'd0;
//             start = 1'd0;
//             repeated_start = 1'd1;
// $display("XXXXXXXXXXXXX -------- REPTD STRT CAPTURED --- REP BIT: %d",repeated_start );             
//         end
//     end
end

ASSERT_I2C_STOP: assert(stop == 1'd1)else begin
    $display("I2C_STOP: I2C stop assert failed");
    $error;
end

endtask 


task wait_for_i2c_transfer(output bit op, output bit [I2C_DATA_WIDTH-1:0] write_data[]);

byte_number = 0;
write_data = new[64];
write_data_captured = new[64];

//wait to capture start or repeated start
while( start == 1'd0 )capture_start();
//$display("------------------- start condition received by I2C -----------------------");


//capture address
capture_addr();
op = rw;
// $display("////////////////////// OPERATION ///////////////////////");
// $display("OPERATION:%d" ,op);
// $display("////////////////////////////////////////////////////////");
//send ack
send_ack();


//op == 0. Master writes
if(rw == 1'd0)begin
    while (stop == 1'd0) begin
        fork
            begin
                get_write_data();
                write_data[byte_number]          = write_data_captured[byte_number];
                //write_data_captured[byte_number] = data_in;
                byte_number++;
                // $display("///////////////// WRITE DATA CAPTURED - 2 ///////////// ");
                // $display("            %d          ", write_data[byte_number-1]);
                // $display("///////////////// /////////////////// ///////////// ");

                //send ack
                send_ack();
            end

            //detect stop
            // while(stop == 1'd0)begin
            //     @(posedge sda);
            //     #10;
            //     if(scl && sda)begin
            //         stop = 1'd1;
            //         start = 1'd0;
            //         $display("XXXXXXXXXXXXXXXX STOP DETECTED, STOP: %b XXXXXXXXX", stop);
            //         break;
            //     end
            // end
            capture_stop_repeated_start();
            ////////////////////////
        join_any
        if(stop)begin
            disable fork;
           // $display("------------------- stop condition received by I2C: Write op -----------------------");

            return;
        end
    end    
end


// //op == 1. Master reads
if(rw == 1'd1)begin
    return;
end

endtask

///////////////////////////////////////////////////////////////////////////////////////////////////

task provide_read_data(input bit [I2C_DATA_WIDTH-1:0] read_data[], output bit transfer_complete);

    transfer_complete = 1'd0;
    data_o = new[read_data.size()];

while(transfer_complete == 1'd0) begin    
    for(i=0; i < read_data.size(); i++)begin        
        //$display("~~~~~~~~~~~~~~~SDA HELD:%d ~~~~~~~~~~~~~~~~~~", sda_oe );
        for(int j = I2C_DATA_WIDTH-1; j>=0; j--)begin
            @(posedge scl);
                sda_oe    = 1'd1; //write 1 BYTE to SDA
                sda_bit   = read_data[i][j];
                data_o[i][j] = read_data[i][j];
            
            @(negedge scl);
            sda_oe = 1'd0; //release SDA line. 1 byte completed
            sda_bit = 1'd0;
        end
        
        @(posedge scl); // wait for transmitter to ack
        if(scl && !sda)begin
            //transfer not complete
            transfer_complete = 1'd0;
        end
        else begin
            //reciever didn't ack. Transfer complete
            transfer_complete = 1'd1;
            @(posedge scl);
            //@(posedge sda);
            //@(negedge sda);
            break;
        end

        if( !transfer_complete )begin
            ASSERT_rec_ACK: assert( scl && !sda )else begin
                $display("Recieve asvk failed");
                $error;
            end
        end
        else begin
            ASSERT_NACK: assert( scl && (sda || !sda) ) else begin
                $display("Receive NACK failed");
                $error;
            end
        end
        // $display("######## CURRENT BYTE TRANSFERRED #########");
        // $display("        DATA:%d        ", data_o);
        // $display("###########################################");
    end

    
    if(transfer_complete)break;

end

    //$display("provide data --- return hit");    
    //$display("------------------- stop condition received by I2C: Read op -----------------------");
    return;
endtask

task i2c_monitor(output bit [I2C_ADDR_WIDTH-1:0] addr, output bit op, output bit [I2C_DATA_WIDTH-1:0]data[]);
    addr = addr_in;
    op  = rw;
    
    if(rw == 1'd0)data = write_data_captured; //WRITE OP
    if(rw == 1'd1)data = data_o; // READ OP
endtask 



endinterface