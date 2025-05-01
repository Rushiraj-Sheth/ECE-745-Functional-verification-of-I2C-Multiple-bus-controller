class generator extends ncsu_component#(.T(ncsu_transaction));
    
    wb_transaction wb_trans, wb_t;
    i2c_transaction i2c_trans, i2c_t;
    wb_agent p0_agent;
    i2c_agent p1_agent;
    // this agent is a generalised class. so, IDEALLY all the sub components which
    // receive transac from generator must be of ncsu_transaction type.

    int k;


    function new(string name ="", ncsu_component#(T) parent = null);
        super.new(name,parent);
        ncsu_info("generator::new()",$sformatf("ID: %s",get_full_name()),NCSU_MEDIUM);
    endfunction //new()
    ////////////////////////////////////////////////////////////////////////

    // set current agent
    function void set_agent(wb_agent p0_agent, i2c_agent p1_agent);
        this.p0_agent = p0_agent;
        this.p1_agent = p1_agent;
    endfunction
    ////////////////////////////////////////////////////////////////////////

    // receive transaction from test class
    function void set_master_transaction(wb_transaction wb_trans);
        this.wb_trans = wb_trans;
    endfunction

    function void set_slave_transaction(i2c_transaction i2c_trans);
        this.i2c_trans = i2c_trans;
    endfunction
    ///////////////////////////////////////////////////////////////////////


    ///////////////////////////////////////////////////////////////////////
    // send transac to agent
    virtual task run();

    test1(); //wb writes
    test2(); //wb reads
    test3(); //alternate RW

    


    endtask
    ////////////////////////////////////////////////////////////////////////



    ////////////////////////////////////////////////////////////////////////
    task  test1();

        $display("################### TEST 1 ##########################");
        $display("Write 32 incrementing values: 0 to 31; to the I2C bus");
        $display("#####################################################");

        /////////////////////// WB /////////////////////////////////////////////////
        write_data_to_slave = new[32];

        for(int i=0;i<32;i++)begin
            write_data_to_slave[i] = i;
        end

        top_bytes_to_transact = 32;

        wb_t = new("wb_trans",0,1'd0,8'h22,32);
        wb_t.data = new[32];
        wb_t.data = write_data_to_slave;
        
        this.set_master_transaction(wb_t);
        /////////////////////////////////////////////////////////////////////////////

        ////////////////////////////// I2C /////////////////////////////////////////
        i2c_t = new( .name("i2c_trans") );
        this.set_slave_transaction(i2c_t);
        ////////////////////////////////////////////////////////////////////////////
        
        fork
            begin p0_agent.bl_put(wb_trans); end
            begin p1_agent.bl_put(i2c_trans); end    
        join
        //disable fork;

        $display("################### TEST 1 FINISH ##########################");
        $display("Write 32 incrementing values: 0 to 31; to the I2C bus");
        $display("############################################################");
    endtask //
    ////////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////////
    task test2();

        $display("################### TEST 2 ##########################");
        $display("Read 32 values from I2C Bus");
        $display("#####################################################");

        top_bytes_to_transact = 32;
        read_data_for_slave = new[32];

        // send below to i2c provide read data
        for(int i=0;i<32;i++)begin
            read_data_for_slave[i] = i + 100;
        end

        // //receive data from i2c to wb
        // read_data_from_slave = new[32];

        //define transactions
        wb_t = new("wb_trans",
                    .bus_num(0),
                    .op(1'd1),
                    .addr(8'h22),
                    .bytes(top_bytes_to_transact)
                    );
        
        wb_t.data = new[32];
        this.set_master_transaction(wb_t);
        /////////////////////////////////////////////

        ///////////////// I2C ////////////////////////
        i2c_t = new(.name("i2c_trans"));
        i2c_t.data = new[32];
        i2c_t.data = read_data_for_slave;
        this.set_slave_transaction(i2c_t);
        /////////////////////////////////////////////

        fork
            begin p0_agent.bl_put(wb_trans); end
            begin p1_agent.bl_put(i2c_trans); end    
        join
        //disable fork;

        $display("################### TEST 2 FINISH ##########################");
        $display("Read 32 values from I2C Bus");
        $display("############################################################");        

    endtask
    ////////////////////////////////////////////////////////////////////////


    ////////////////////////////////////////////////////////////////////////
    task test3();

        $display("############################# TEST 3 ################################");
        $display("Alternate READ and WRITES | Write data: 64 to 127 | read data:63 to 0");
        $display("#####################################################################");

        ///////////////////////////// WB ///////////////////////////
        top_bytes_to_transact = 1;
        write_data_to_slave = new[64]; //wrtie data
        for(int i=0; i<write_data_to_slave.size();i++)begin
            write_data_to_slave[i] = i + 64;
        end

        //temp_write_data_to_slave = new[1];
        

        ///////////////////////////////////////////////////////////

        ///////////////////// i2c data ////////////////////////////
        read_data_for_slave = new[64];
        //temp_read_data_for_i2c = new[1];

        for(int i = 0; i < 64; i++)begin
            read_data_for_slave[i] = 63-i;
        end

        
        //i2c_t.data = new[1];
        ///////////////////////////////////////////////////////////

        //////////////// sending transactions /////////////////////

        //wb writes
        repeat(64) begin
            wb_t = new(.name("wb_trans"),
                        .bus_num(0),
                        .op(1'd0),
                        .addr(8'h22),
                        .bytes(top_bytes_to_transact)
                        );

            wb_t.data = new[1];
            wb_t.data[0] = write_data_to_slave[k];//k 

            i2c_t = new(.name("i2c_trans"));
            
            this.set_master_transaction(wb_t);
            this.set_slave_transaction(i2c_t);

            //////////////////////////////////////////////
            fork
                begin p0_agent.bl_put(wb_trans); end
                begin p1_agent.bl_put(i2c_trans); end    
            join
            //disable fork;
            //////////////////////////////////////////////

            //wb_reads
            wb_t = new(.name("wb_trans"),
                        .bus_num(0),
                        .op(1'd1),
                        .addr(8'h22),
                        .bytes(top_bytes_to_transact)
                        );
            wb_t.data = new[1]; //receive 1 byte from i2c slave

            i2c_t = new(.name("i2c_trans"));
            i2c_t.data = new[1];
            i2c_t.data[0] = read_data_for_slave[k];
            
            this.set_master_transaction(wb_t);
            this.set_slave_transaction(i2c_t);

            //////////////////////////////////////////////
            fork
                begin p0_agent.bl_put(wb_trans); end
                begin p1_agent.bl_put(i2c_trans); end    
            join
            //disable fork;
            //////////////////////////////////////////////
                 
            k++;
        end
        ///////////////////////////////////////////////////////////
        disable fork;
        $display("######################### TEST 3 FINISH #############################");
        $display("Alternate READ and WRITES | Write data: 64 to 127 | read data:63 to 0");
        $display("#####################################################################");

    endtask
    ////////////////////////////////////////////////////////////////////////


endclass //generator extends ncsu_component#(.T(ncsu_transaction))