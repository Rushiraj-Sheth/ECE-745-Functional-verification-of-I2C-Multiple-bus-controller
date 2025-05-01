class wb_monitor extends ncsu_component #(.T( ncsu_transaction ) );
    
    //this class is used to call the monitor task of interface
    virtual wb_if wb_bus;
    wb_configuration configuration;
    wb_transaction monitered_trans; //wb_transaction type
    ncsu_component #(T) monitor_parent;

    event wb_event;

    function new(string name="",ncsu_component #(T) parent=null);
        super.new(name,parent);
        super.build();
    endfunction //new()

    function void set_configuration(wb_configuration cfg);
        configuration = cfg;        
    endfunction

    //use the run task of ncsu_component
    // recieve the monitered data from wb_monitor and then print it
    virtual task run();
        //wait till reset occurs
        wb_bus.wait_for_reset();
        forever begin
            //@(wb_event);
            monitered_trans = new( .name("monitered_trans") ); //rest of the parameters are taken as default. Doesn't matter
            //but using the config handle we can specify them also -- slave address and bus no
            wb_bus.master_monitor(.addr(monitered_trans.slave_addr), .data(monitered_trans.monitered_wb_data),
                                         .we(monitered_trans.op));

            /*ncsu_info("wb_monitor::run()",$sformatf(" of %s called.\n wb_register/slave_Addr: 0x%h,\n OP: %01b,\n data: %0d", 
                        get_full_name(), monitered_trans.slave_addr, monitered_trans.op, monitered_trans.monitered_wb_data),NCSU_MEDIUM ); */ 

            $cast(monitor_parent, parent);
            monitor_parent.nb_put(monitered_trans);
        end
    endtask

endclass //wb_monitor extends superClass