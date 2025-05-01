class i2c_monitor extends ncsu_component#(.T(ncsu_transaction));
    
    //bit [I2C_DATA_WIDTH-2:0] data[];

    i2c_configuration config_handle; //handle pointing to i2c_configuration object
    virtual i2c_if i2c_bus;
    event i2c_event;
    i2c_transaction monitered_trans;
    ncsu_component #(T) monitor_parent;

    function new(string name="", ncsu_component #(T) parent=null);
        super.new(name,parent);
        super.build();
    endfunction //new()

    function void set_configuration(i2c_configuration cfg);
        config_handle = cfg;
    endfunction

    virtual task run();
        //wait till start occurs   
        forever begin
           @(i2c_event);
            monitered_trans = new( .name("monitered_trans") );
            i2c_bus.i2c_monitor(.addr(monitered_trans.slave_addr), 
                                .op(monitered_trans.op),
                                .data(monitered_trans.data));
            ncsu_info("i2c_monitor::run()", 
                        $sformatf(" of %s called.\n Slave address:0x%h;\n RW:%01b;\n Data:%0d",
                        get_full_name(),monitered_trans.slave_addr,monitered_trans.op,monitered_trans.data), 
                        NCSU_MEDIUM);
            
            //send i2c transaction object to parent component through nb_put i.e. parent = agent
            $cast(monitor_parent, parent);
            monitor_parent.nb_put(monitered_trans); //this calls nb_put of agent. and i have not implemeted it.
        end
    endtask

endclass //i2c_monitor extends ncsu_component#(.T(i2c_transaction))