class i2c_transaction extends ncsu_transaction;
    
    //define variables of a transaction
    bit op; //read or write
    bit transfer_complete = 1'd0;
    bit [I2C_ADDR_WIDTH-1:0] slave_addr; //slave address
    bit [I2C_DATA_WIDTH-1:0] data[];
    //bit [I2C_DATA_WIDTH-1:0] write_data[];
    int bus_num;
    i2c_transaction rhs;

    function new(string name="");
        super.new(name);
    endfunction //new()

    virtual function string convert2string();
        return {super.convert2string(), 
                $sformatf("obj name:%s,\n op type:%0d,\n slave_addr_captured:%08h,\n bus_no:%d,\n Data:%0d,\n transfer_stat: %01b\n",
                name,op,slave_addr,bus_num, data, transfer_complete)};
    endfunction

    function bit compare(ncsu_transaction ncsu_rhs);
        $cast(this.rhs,ncsu_rhs);
        return (
            (this.name == rhs.name) &&
            (this.slave_addr == rhs.slave_addr) &&
            (this.op == rhs.op) &&
            (this.data == rhs.data)
        );
    endfunction

//Add to wave ??
    virtual function void add_to_wave(int transaction_viewing_stream_h);
        super.add_to_wave(transaction_viewing_stream_h);
        $display("transaction started. time:%0t", start_time);
        $add_attribute( transaction_view_h, name, "object name" );
        $add_attribute(transaction_view_h, op,"operation type");
        $add_attribute(transaction_view_h, slave_addr, "slave address");
        $add_attribute(transaction_view_h,bus_num, "bus number");
        $add_attribute(transaction_view_h,data, "data");
        $end_transaction(transaction_view_h,"End transaction", end_time);
        $display("transaction ended. End time:%0t", end_time);
        $free_transaction(transaction_view_h);
    endfunction
endclass //i2c_transaction extends superClass