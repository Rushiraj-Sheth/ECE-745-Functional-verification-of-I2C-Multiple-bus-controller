`timescale 1ns / 10ps

// `define TEST1
// `define TEST2
`define TEST3

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;//1
parameter int I2C_ADDR_WIDTH = 7; 
parameter int I2C_DATA_WIDTH = 8;

bit  clk = 1'b0;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

///////////// user defined variables ////////////
bit [WB_DATA_WIDTH-1:0]cmdr = 8'd0;

bit [WB_DATA_WIDTH-1:0] data;
bit [WB_ADDR_WIDTH-1:0] addr;
bit we_stat;

bit [I2C_DATA_WIDTH-1:0] write_data_to_slave[];
bit [I2C_DATA_WIDTH-1:0] read_data_from_slave[];
bit [I2C_DATA_WIDTH-1:0] read_data_for_i2c[];
bit [I2C_DATA_WIDTH-1:0] i2c_write_data[];

bit [I2C_DATA_WIDTH-1:0] temp_write_data_to_slave[];
bit [I2C_DATA_WIDTH-1:0] temp_read_from_slave[];


bit i2c_read_write = 1'd0;
bit tc_bit = 1'd0;
int bytes_to_transact = 0;
int k=0,itr_i2c=0;

bit [I2C_ADDR_WIDTH-1:0] mon_i2c_addr;
bit [I2C_DATA_WIDTH-1:0] mon_i2c_data[];
bit mon_i2c_rw;
event i2c_event;

////////////////////////////////////////////////

// ****************************************************************************
// Clock generator
initial clk_gen :begin
forever #10ns clk = ~clk;
//$display("user clk: "0x%d,clk);
end : clk_gen



// ****************************************************************************
// Reset generator
initial rst_gen : begin
#113ns rst = ~rst;
end: rst_gen



// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
always @(posedge clk) wb_monitoring: begin
  wb_bus.master_monitor(.addr(addr),.data(data),.we(we_stat));
  if(we_stat)begin
    $display("WB write address transferred: %08b | Decimal val:%d ",addr,addr);
    $display("WB write data:%h, Decimal:%d ",data, data);
    $display("\n");
  end
  else begin
    $display("WB read address transferred: %08b | Decimal val:%d",addr,addr);
    $display("WB read data:%h, Decimal val:%d ",data,data);
    $display("\n");
  end
end : wb_monitoring

// ****************************************************************************
// monitor i2c bus
initial begin: monitor_i2c_bus
forever begin

  @(i2c_event);
  i2c_bus.i2c_monitor(.addr(mon_i2c_addr), .data(mon_i2c_data), .op(mon_i2c_rw));
  if(mon_i2c_rw == 1'd0)begin
    $display("--------- I2C_BUS WRITE TRANSFER: ----------");
    $display("I2C address transferred: 0x%h | Decimal val: %d" , mon_i2c_addr, mon_i2c_addr);
    $display("I2C RW bit: %02b ", mon_i2c_rw);
    $display("I2C write data tranferred (Decimal val of data): %0d \n", $unsigned(mon_i2c_data) );
  end

  if(mon_i2c_rw == 1'd1)begin
    $display("------- I2C_BUS READ TRANSFER: ------------ ");
    $display("I2C address transferred: 0x%h | Decimal val: %d" , mon_i2c_addr, mon_i2c_addr);
    $display("I2C RW bit: %02b ", mon_i2c_rw);
    $display("I2C read data tranferred (Decimal val of data): %0d \n", mon_i2c_data );
  end
 
end 

end : monitor_i2c_bus

// ****************************************************************************
// Define the flow of the simulation
initial test_flow : begin
#120

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
`ifdef TEST1
  $display("################### TEST 1 ##########################");
  $display("Write 32 incrementing values: 0 to 31; to the I2C bus");
  $display("#####################################################");

  write_data_to_slave = new[32];
  bytes_to_transact   = 32;

  for(int i=0;i<32;i++)begin
    write_data_to_slave[i] = i;
  end
  wb_master_write(write_data_to_slave, bytes_to_transact);

`endif
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`ifdef TEST1
$display("################### TEST 1 FINISH ##########################");
$display("Write 32 incrementing values: 0 to 31; to the I2C bus");
$display("############################################################");
`endif
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
`ifdef TEST2
  
  $display("################### TEST 2 ##########################");
  $display("Read 32 values from I2C Bus");
  $display("#####################################################");

  bytes_to_transact = 32;
  write_data_to_slave = new[32];
  for(int i=0; i<32;i=i+1)begin
    write_data_to_slave[i] = i + 100;    
  end

  read_data_from_slave = new[32];
  for(int i=0;i<32;i++)begin
    read_data_from_slave[i] = 8'b0;
  end
  
  wb_master_reads(read_data_from_slave, bytes_to_transact);

`endif 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
`ifdef TEST2
  $display("################### TEST 2 FINISH ##########################");
  $display("Read 32 values from I2C Bus");
  $display("############################################################");
`endif
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

`ifdef TEST3
  $display("############################# TEST 3 ################################");
  $display("Alternate READ and WRITES | Write data: 64 to 127 | read data:63 to 0");
  $display("#####################################################################");

  bytes_to_transact = 1; //transfer 1 byte for each operation, at a time
  //will send below data one by one to the i2c slave
  write_data_to_slave = new[64];
  for(int i=0; i<write_data_to_slave.size();i++)begin
    write_data_to_slave[i] = i + 64;
  end

  //initialse an array to collect read data from I2C
  read_data_from_slave = new[64];
  
  temp_write_data_to_slave = new[1];
  temp_read_from_slave = new[1];
  k=0;
  //Now initiate alternate reads and writes
  repeat(64)begin
    temp_write_data_to_slave[0] = write_data_to_slave[k];
    wb_master_write(temp_write_data_to_slave, bytes_to_transact);
    //$display("$$$$$$$$$$$$ WRITE_DONE TRIGGRED $$$$$$$$$$$$$$$$ | time: %0t",$realtime);    
  

    wb_master_reads(temp_read_from_slave, bytes_to_transact);
    read_data_from_slave[k] = temp_read_from_slave[0];
    //$display("$$$$$$$$$$$$ READ_DONE TRIGGRED $$$$$$$$$$$$$$$$ | time:%0t", $realtime);
    k++;
  end

`endif 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  `ifdef TEST3
  $display("######################### TEST 3 FINISH #############################");
  $display("Alternate READ and WRITES | Write data: 64 to 127 | read data:63 to 0");
  $display("#####################################################################");
  `endif

 #10000
 $finish();

end : test_flow

//////////////////////////////////////////////////////////////////////////////////////////
task wait_till_DON();

  cmdr = 8'd0;
  while(!irq)@(posedge clk);
  //while(cmdr == 8'd0)
  wb_bus.master_read(.addr(2'd2), .data(cmdr));
  $display("Wishbone DON bit/irq status");
  casex (cmdr)
    8'b1xxxxxxx:begin $display("command is done. CMDR val: %08b | time: %0t \n", cmdr, $realtime);end
    8'bx1xxxxxx:begin $display("slave did not respond. CMDR val: %08b | time: %0t \n", cmdr, $realtime); end
    8'bxx1xxxxx:begin $display("Arbitration Lost. CMDR val: %08b | time: %0t \n", cmdr, $realtime); end
    8'bxxx1xxxx:begin $display("ERROR. CMDR val: %08b | time: %0t", cmdr, $realtime); end
    default: begin $display("command unsuccessful. CMDR Val: %08b | time: %0t \n", cmdr, $realtime); end
  endcase

endtask : wait_till_DON
/////////////////////////////////////////////////////////////////////////////////////////////

//**************************************************************************************
//test flow for I2C bus

initial i2c_test_flow : begin

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
`ifdef TEST1
  i2c_bus.wait_for_i2c_transfer(.op(i2c_read_write), .write_data(i2c_write_data));
`endif
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
`ifdef TEST2
  i2c_bus.wait_for_i2c_transfer(.op(i2c_read_write), .write_data(i2c_write_data));  
  i2c_bus.provide_read_data(.read_data(write_data_to_slave), .transfer_complete(tc_bit) );  
`endif 
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
`ifdef TEST3
  itr_i2c=0;
  //Need to send read_data to i2c, for transmitting it to the Master/reciever
  read_data_for_i2c = new[1];

  repeat(128)begin
    i2c_read_write = 1'd0;
    tc_bit = 1'd0;
    i2c_bus.wait_for_i2c_transfer(.op(i2c_read_write), .write_data(i2c_write_data));
    
    if(i2c_read_write == 1'd1)begin
      //read operation
      //while(tc_bit == 1'd0)begin
        read_data_for_i2c[0] = 63-itr_i2c;
        i2c_bus.provide_read_data(.read_data(read_data_for_i2c), .transfer_complete(tc_bit));
      //end
      itr_i2c++;
    end

  end

`endif

end : i2c_test_flow

//////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////// MASTER WRITES //////////////////////////////////////////////

task automatic wb_master_write( ref bit [I2C_DATA_WIDTH-1:0]write_data_to_slave[], ref int bytes_to_transact );
  //CMDR = 0x02; DPR = 0x01; CSR = 0x00

  // //set enable bit 1 and enable interrupt 1 in CSR
   wb_bus.master_write(.addr(2'b00),.data(8'b11xxxxxx));

  //write bus id as 0 to DPR
  wb_bus.master_write(.addr(2'b01), .data(8'd0));


  //write set bus command to CMDR
  wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx110));

  //wait for interrupt or till DON bit of CMDR reads 1
  wait_till_DON();


  //write byte 'xxxxx100' to cmdr. this is start cmd
  wb_bus.master_write(.addr(2'd2),.data(8'bxxxxx100));

  //wait for interrupt or till DON bit of CMDR reads 1
  wait_till_DON();

  //Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 1 bit to the left +
  //rightmost bit = '0', which means writing
  wb_bus.master_write(.addr(2'd1), .data(8'h44));


  //write byte xxxxx001 to cmdr. --> write cmd
  wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx001));

  //wait for interrupt or till DON bit of CMDR reads 1
  wait_till_DON();

  ->i2c_event; //i2c_monitor

  ///////////////// ENTER VALUES BELOW ///////////////////////////////
  //write 0x78 to DPR. Enter data val here.
  for(int i=0; i<bytes_to_transact; i=i+1)begin
  
    wb_bus.master_write(.addr(2'd1),.data(write_data_to_slave[i]));

    //write byte xxxxx001 to cmdr. --> write comd
    wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx001));

    wait_till_DON();
    
    ->i2c_event; //i2c_monitor
  end
  ///////////////////////////////////////////////////////////////////

  //wrtie xxxxx101 to cmdr. -->stop cmd
  wb_bus.master_write(.addr(2'd2),.data(8'bxxxxx101));
  //wait 
  wait_till_DON();

//  ->i2c_event; //i2c_monitor

endtask : wb_master_write
/////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////// MASTER READS /////////////////////////////////////////////
task automatic wb_master_reads(ref bit[I2C_DATA_WIDTH-1:0] read_data_from_slave[], ref int bytes_to_transact);

  // //set enable bit 1 and enable interrupt 1 in CSR
   wb_bus.master_write(.addr(2'b00),.data(8'b11xxxxxx));
  
  // CMDR = 0x02; DPR = 0x01; CSR = 0x00
  // Write byte 0x01 to the DPR. This is the ID of desired I2C bus.
  // i am writing bus id = 0
  wb_bus.master_write(.addr(2'd1), .data(8'd0));

  // Write byte “xxxxx110” to the CMDR. This is Set Bus command
  wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx110));

  // Wait for interrupt or until DON bit of CMDR reads '1'
  wait_till_DON();

  // Write byte “xxxxx100” to the CMDR. This is Start command
  wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx100));

  // Wait for interrupt or until DON bit of CMDR reads '1'
  wait_till_DON();

  // Write byte 0x89 to the DPR. This is the slave address 0x44 shifted 1 bit to the left +
  // rightmost bit is '1' which means reading
  wb_bus.master_write(.addr(2'd1),.data(8'h45));

  //Write byte “xxxxx001” to the CMDR. This is Write command.
  wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx001));

  //Wait for interrupt or until DON bit of CMDR reads '1'.
  wait_till_DON();

  ->i2c_event; //i2c_monitor

  //////////////////// DATA RECIEVE /////////////////////////////////
  //Write byte “xxxxx010” to the CMDR. This is Read With Ack command.
  for(int i=0; i<bytes_to_transact-1; i++)begin
    //Write byte “xxxxx010” to the CMDR. This is Read With Ack command.
    wb_bus.master_write(.addr(2'd2), .data(8'b00000010));

    //Wait for interrupt or until DON bit of CMDR reads '1'.
    wait_till_DON();

    //Read DPR to get received byte of data. 
    wb_bus.master_read(.addr(2'd1), .data(read_data_from_slave[i]));
    // $display("##################################################");
    // $display(" CURRENT BYTE CAPTURE:%d", read_data_from_slave[i]); 
    // $display("##################################################");
    ->i2c_event; //i2c_monitor 
  end

  //Read last byte with NACK telling SLAVE to stop and release the bus back to the master
  //Write byte “xxxxx011” to the CMDR. This is Read command with NACK
  wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx011) );

  //wait for interrupt or until DON bit of CMDR reads 1
  wait_till_DON();
  // READ data from DPR
  wb_bus.master_read(.addr(2'd1), .data( read_data_from_slave[bytes_to_transact-1]) );

  ->i2c_event; //i2c_monitor

  // $display("##################################################");
  // $display(" LAST BYTE CAPTURED:%d", read_data_from_slave[bytes_to_transact-1]); 
  // $display("##################################################");
  //////////////////////////////////////////////////////////////////

  //Write byte “xxxxx101” to the CMDR. This is Stop command.
  wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx101));

  //Wait for interrupt or until DON bit of CMDR reads '1'.
  wait_till_DON();  

 // ->i2c_event; //i2c_monitor
//$display("------------------- stop condition received by I2C: Read op -----------------------");
endtask : wb_master_reads
/////////////////////////////////////////////////////////////////////////////////////////////

  
// ****************************************************************************
// Instantiate the I2C interface
i2c_if #(.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH), 
        .I2C_DATA_WIDTH(I2C_DATA_WIDTH)
      )
i2c_bus(
  .rst_i(rst),
  .scl(scl),
  .sda(sda)
);       

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );


endmodule
