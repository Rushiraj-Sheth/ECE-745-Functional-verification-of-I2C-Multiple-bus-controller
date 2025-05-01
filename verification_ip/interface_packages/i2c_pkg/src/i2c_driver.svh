class i2c_driver extends ncsu_component#(.T(ncsu_transaction));
    
    function new(string name="", ncsu_component #(T) parent=null);
        super.new(name, parent);
        super.build();
    endfunction //new()

    virtual i2c_if i2c_bus; // will use this to send backup data to i2c for read transfer
    i2c_configuration config_handle; //handle pointing to i2c_configuration object
    i2c_transaction transact; //handle pointing to a particular i2c transaction

    bit [I2C_DATA_WIDTH-1:0] temp_data[];

    function void set_configuration(i2c_configuration cfg);
        config_handle = cfg;
    endfunction
    
    virtual task bl_put(input T trans);
        //the transaction recieved here is of ncsu_transaction - base class type
        // and our handle is of derived class type - i2c transaction
        // derived_class_handle = base_class_handle --- cannot assign. need to cast it
        $cast(transact,trans);
        ncsu_info("i2c_driver::bl_put()", $sformatf(" of %s called",get_full_name()), NCSU_MEDIUM);
        
        //send the transaction to i2c bus
        i2c_bus.wait_for_i2c_transfer(.op(transact.op),.write_data(temp_data));
        if(transact.op == 1'd1)begin
            i2c_bus.provide_read_data(.read_data(transact.data), 
                                        .transfer_complete(transact.transfer_complete) 
                                    );    
        end
        else begin
            transact.data = temp_data;
        end

        //also print transaction details
        //$display("%s",transact.convert2string());        
    endtask


endclass //i2c_driver extends superClass