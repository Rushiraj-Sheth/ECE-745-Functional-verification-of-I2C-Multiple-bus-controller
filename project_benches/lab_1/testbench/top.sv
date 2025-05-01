`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

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

bit [WB_DATA_WIDTH-1:0]cmdr = 8'd0;
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
bit [WB_DATA_WIDTH-1:0] data;
bit [WB_ADDR_WIDTH-1:0] addr;
bit we_stat;
always @(posedge clk) wb_monitoring: begin
  wb_bus.master_monitor(.addr(addr),.data(data),.we(we_stat));
  if(we_stat)begin
  $display("user write address transferred: 0x%x\n",addr);
  $display("user data transferred: 0x%x\n",data);
  end
  else begin
  $display("user read address transferred: 0x%x\n",addr);
  $display("user data transferred: 0x%x\n",data);
  end
end : wb_monitoring

// ****************************************************************************
// Define the flow of the simulation
initial test_flow : begin
#120
//set enable bit 1 and enable interrupt 1
wb_bus.master_write(.addr(8'h00),.data(8'b11000000));
//write bus id as 05 to DPR
wb_bus.master_write(.addr(8'h01), .data(8'd5));
//write set bus command to CMDR
wb_bus.master_write(.addr(8'h02), .data(8'bxxxxx110));
//wait for interrupt or till DON bit of CMDR reads 1
wait_till_DON();
//write byte 'xxxxx100' to cmdr. this is start cmd
wb_bus.master_write(.addr(8'h02),.data(8'bxxxxx100));
//wait for interrupt or till DON bit of CMDR reads 1
wait_till_DON();
//write 0x44 to DPR
wb_bus.master_write(.addr(8'h01), .data(8'h44));
//write byte xxxxx001 to cmdr. --> write comd
wb_bus.master_write(.addr(8'h02), .data(8'bxxxxx001));
//wait for interrupt or till DON bit of CMDR reads 1
wait_till_DON();
//write 0x78 to DPR
wb_bus.master_write(.addr(8'h01),.data(8'h78));
//write byte xxxxx001 to cmdr. --> write comd
wb_bus.master_write(.addr(8'h02), .data(8'bxxxxx001));
wait_till_DON();
//wrtie xxxxx101 to cmdr. -->stop cmd
wb_bus.master_write(.addr(8'h02),.data(8'bxxxxx101));
//wait 
wait_till_DON();

$finish();
end : test_flow

task wait_till_DON();
begin

while(!irq)@(posedge clk);

//while (cmdr == 8'd0) begin
  wb_bus.master_read(.addr(8'h02), .data(cmdr));
//end
@(posedge clk)
casex (cmdr)
  8'b1xxxxxxx:begin $display("command is done");end
  8'bx1xxxxxx:begin $display("slave did not respond"); end
  8'bxx1xxxxx:begin $display("Arbitation Lost"); end
  8'bxxx1xxxx:begin $display("ERROR "); end
  default: begin $display("command unsuccessful. CMDR Val: 0x%h", cmdr); end
endcase
end
endtask

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
