class coverage extends ncsu_component#(.T(ncsu_transaction));

    wb_transaction trans;

    covergroup env_coverage_cg;
        option.per_instance = 1;
        option.name = name;
        REG_ADDR: coverpoint trans.slave_addr{
            bins cmdr = {'d2};
            bins dpr = {'d1};
        }

        SET_BUS_CMD: coverpoint trans.monitered_wb_data {
            bins set_bus_cmd = { 'd134 };
        }

        SET_BUS: cross REG_ADDR,SET_BUS_CMD{
            bins set_bus = binsof(REG_ADDR.cmdr) && binsof(SET_BUS_CMD);


            ignore_bins dpr_id =  binsof(REG_ADDR.dpr) ;
        }

        OP: coverpoint trans.monitered_wb_data{
            bins slave_addr_and_read_op = {8'h45};
            bins slave_addr_and_write_op = {8'h44};
        }

        DPRxOP: cross REG_ADDR,OP{
            bins read_op =  binsof(REG_ADDR.dpr) && binsof(OP.slave_addr_and_read_op) ;
            bins write_op = binsof(REG_ADDR.dpr) && binsof(OP.slave_addr_and_write_op) ;

            ignore_bins ignore =  binsof(REG_ADDR.cmdr) ;
        }

        READ_ACK: coverpoint trans.monitered_wb_data{
            bins read_ack = {'d130};
        }

        READ_NACK: coverpoint trans.monitered_wb_data{
            bins read_nack = {'d131};
        }

        CMDRxREAD_ACK: cross REG_ADDR,READ_ACK{
            bins cmdr_read_ack =  binsof(REG_ADDR.cmdr)&& binsof(READ_ACK) ;
            ignore_bins ignore =  binsof(REG_ADDR.dpr) ; 
        }  // successful read with ACK in CMDR

        CMDRxREAD_NACK: cross REG_ADDR, READ_NACK{
            bins cmdr_read_nack =  binsof(REG_ADDR.cmdr) && binsof(READ_NACK) ;
            ignore_bins ignore =  binsof(REG_ADDR.dpr) ;
        } // successful read with NACK in CMDR

        START_STOP: coverpoint trans.monitered_wb_data{
            bins start= { 'd132 };
            bins stop = { 'd133 };
        }

        CMDRxSTART_STOP: cross REG_ADDR, START_STOP{
            bins wb_start =  binsof(REG_ADDR.cmdr) && binsof(START_STOP.start) ;
            bins wb_stop =  binsof(REG_ADDR.cmdr) && binsof(START_STOP.stop) ;
            ignore_bins ignore =  binsof(REG_ADDR.dpr)  ;
        }

        STATUS: coverpoint trans.monitered_wb_data{
            bins no_response = { [64:127] };
            bins arbitration_lost = { [32:63] };
            bins error = { [16:31] };
        }

        CMDRxINVALID_STATUS: cross REG_ADDR, STATUS{
            illegal_bins no_response =  binsof(REG_ADDR.cmdr) && binsof(STATUS.no_response) ;
            illegal_bins arbitration_lost =  binsof(REG_ADDR.cmdr) && binsof(STATUS.arbitration_lost) ;
            illegal_bins error =  binsof(REG_ADDR.cmdr) && binsof(STATUS.error) ;

            ignore_bins ignore = binsof(REG_ADDR.dpr)  ;
        }
    endgroup


    env_configuration configuration;

    function new(string name="", ncsu_component #(T) parent = null);    
        super.new(name,parent);
        ncsu_info("coverage::new()",$sformatf("ID: %s",get_full_name()),NCSU_MEDIUM);
        env_coverage_cg = new;
    endfunction //new()

    function void set_configuration(env_configuration cfg);
        configuration = cfg;
    endfunction

    virtual function void build();
        super.build();
    endfunction

    virtual function void nb_put(input T trans);
        $cast(this.trans,trans);
        //sample the coverpoints
        env_coverage_cg.sample();
    endfunction

endclass //coverage extends ncsu_component#(.T(ncsu_transaction))