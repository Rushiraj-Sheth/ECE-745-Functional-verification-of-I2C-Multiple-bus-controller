parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;


int top_bytes_to_transact = 0;
bit [WB_DATA_WIDTH-1:0] write_data_to_slave[];
// bit [WB_DATA_WIDTH-1:0] temp_write_data_to_slave[];
// bit [WB_DATA_WIDTH-1:0] temp_read_data_for_i2c[];

bit [WB_DATA_WIDTH-1:0]cmdr = 8'd0;