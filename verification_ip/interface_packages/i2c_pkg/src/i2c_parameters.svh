parameter int I2C_DATA_WIDTH = 8;
parameter int I2C_ADDR_WIDTH = 7;
parameter int NUM_I2C_BUSSES = 1;

bit [I2C_DATA_WIDTH-1:0] read_data_for_slave[];