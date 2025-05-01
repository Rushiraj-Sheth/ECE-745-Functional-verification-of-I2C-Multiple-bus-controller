class wb_transaction extends ncsu_transaction;
    //define variables for transaction
    int bus_num;
    bit op = 1'd0;
    bit [WB_ADDR_WIDTH-1:0] slave_addr; //
    bit [WB_DATA_WIDTH-1:0] data[];
    bit [WB_DATA_WIDTH-1:0] monitered_wb_data;
    int bytes_to_transact;
    wb_transaction rhs;

    function new(string name="",int bus_num=0,bit op=1'd0,bit [WB_ADDR_WIDTH-1:0]addr=8'd0, 
                    int bytes = 1);
        super.new(name);
        this.op = op;
        this.bus_num = bus_num;
        this.slave_addr = addr;
        this.bytes_to_transact = bytes;
    endfunction //new()

    virtual function string convert2string();
        return {super.convert2string(), 
                $sformatf("obj name:%s,\n op type:%0d,\n wb_register/slave_addr:%08h,\n bus_no:%0d,\n Data:%0d\n ", 
                name,op,slave_addr,bus_num, monitered_wb_data)};
    endfunction

    function bit compare(ncsu_transaction ncsu_rhs);
        $cast(this.rhs,ncsu_rhs);
        return (
            (this.name == rhs.name) &&
            (this.slave_addr == rhs.slave_addr) && 
            (this.monitered_wb_data == rhs.monitered_wb_data) &&
            (this.op == rhs.op)
        );
    endfunction

    virtual function void add_to_wave(int transaction_viewing_stream_h);
        super.add_to_wave(transaction_viewing_stream_h);
        $display("transaction started. time:%0t", start_time);
        $add_attribute( transaction_view_h, name, "object name" );
        $add_attribute( transaction_view_h, op,"operation type");
        $add_attribute( transaction_view_h, slave_addr, "wb slave address");
        $add_attribute(transaction_view_h,bus_num, "bus number");
        $add_attribute(transaction_view_h,data, "data");
        $end_transaction(transaction_view_h,"End transaction", end_time);
        $display("transaction ended. End time:%0t", end_time);
        $free_transaction(transaction_view_h);
    endfunction

endclass //wb_transaction  extends ncsu_transaction