class wb_driver extends ncsu_component #(.T(ncsu_transaction) );

    virtual wb_if wb_bus;
    wb_configuration config_handle; //handle pointing to wb_configuration object
    wb_transaction transact; //handle pointing to a particular wb_transaction

    event i2c_event;
    event wb_event;
    bit[7:0] data;

    function new(string name="",ncsu_component #(T) parent = null);
        super.new(name,parent);
        super.build();
    endfunction //new()

    function void set_configuration(wb_configuration cfg);
        config_handle = cfg;
    endfunction

    virtual task bl_put(input T trans);
        //the transaction recieved here is of ncsu_transaction - base class type
        // and our handle is of derived class type - wb transaction
        // its ok bcz the method is virtual. but still, we can cast it.
        // derived_class_handle = base_class_handle --- cannot assign. need to cast it
        $cast(transact,trans);

        ncsu_info("START: wb_driver::run()", $sformatf(" of %s is called.",get_full_name()),NCSU_MEDIUM);
       // $display("%s",transact.convert2string()); //displays transaction received by wb_driver
        if(transact.op == 1'd0)begin
            //write operation
            wb_master_write(transact.data,transact.bytes_to_transact);
        end
        else begin
            //read operation
            wb_master_reads(transact.data, transact.bytes_to_transact);
        end
        ncsu_info("FINISH: wb_driver::run()", $sformatf(" of %s is called.",get_full_name()),NCSU_MEDIUM);
        //$display("WB transaction done:\n Data: %s",transact.data); //displays transaction received by wb_driver
    endtask





    ///////////////////////////////// MASTER WRITES //////////////////////////////////////////////
    task automatic wb_master_write( ref bit [WB_DATA_WIDTH-1:0]write_data_to_slave[], 
                                    ref int bytes_to_transact );
        //CMDR = 0x02; DPR = 0x01; CSR = 0x00

        // //set enable bit 1 and enable interrupt 1 in CSR
        wb_bus.master_write(.addr(2'b00),.data(8'b11xxxxxx));

        //write bus id as 0 to DPR
        wb_bus.master_write(.addr(2'b01), .data(8'd0));


        //write set bus command to CMDR
        wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx110));

        //wait for interrupt or till DON bit of CMDR reads 1
        wait_till_DON();

        //write byte 'xxxxx100' to cmdr. this is start cmd
        wb_bus.master_write(.addr(2'd2),.data(8'bxxxxx100));

        //wait for interrupt or till DON bit of CMDR reads 1
        wait_till_DON();



        /////////////////////////////////////////////////
        wb_bus.master_read(.addr(2'd2),.data(data));
        ASSERT_START: assert(data == 8'b10000100)
        else begin
            $display("start error: %08b",data);
            ncsu_error("ASSERT_START","WB START cmd failed");
        end
        /////////////////////////////////////////////////



        //Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 1 bit to the left +
        //rightmost bit = '0', which means writing
        wb_bus.master_write(.addr(2'd1), .data(8'h44));


        //write byte xxxxx001 to cmdr. --> write cmd
        wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx001));

        //wait for interrupt or till DON bit of CMDR reads 1
        wait_till_DON();

        ///////////////// ENTER VALUES BELOW ///////////////////////////////
        //write 0x78 to DPR. Enter data val here.
        for(int i=0; i<bytes_to_transact; i=i+1)begin
            wb_bus.master_write(.addr(2'd1),.data(write_data_to_slave[i]));
            $display("wb_data_sent: %d",write_data_to_slave[i]);

            //write byte xxxxx001 to cmdr. --> write comd
            wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx001));
            
            wait_till_DON();
            
            ->i2c_event; //i2c_monitor
        end
        ///////////////////////////////////////////////////////////////////

        //wrtie xxxxx101 to cmdr. -->stop cmd
        wb_bus.master_write(.addr(2'd2),.data(8'bxxxxx101));
        //wait 
        wait_till_DON();



        //////////////////////////////////
        wb_bus.master_read(.addr(2'd2), .data(data));
        ASSERT_STOP: assert(data == 8'b10000101)
        else begin
            $display("stop error: %08b",data);
            ncsu_error("ASSERT_STOP","wb STOP cmd failed");
        end
        /////////////////////////////////
        //  ->i2c_event; //i2c_monitor



        endtask : wb_master_write
    /////////////////////////////////////////////////////////////////////////////////////////////








    /////////////////////////////////// MASTER READS /////////////////////////////////////////////
    task automatic wb_master_reads(ref bit[WB_DATA_WIDTH-1:0] read_data_from_slave[], 
                                    ref int bytes_to_transact);
        // //set enable bit 1 and enable interrupt 1 in CSR
        wb_bus.master_write(.addr(2'b00),.data(8'b11xxxxxx));
        
        // CMDR = 0x02; DPR = 0x01; CSR = 0x00
        // Write byte 0x01 to the DPR. This is the ID of desired I2C bus.
        // i am writing bus id = 0
        wb_bus.master_write(.addr(2'd1), .data(8'd0));

        // Write byte “xxxxx110” to the CMDR. This is Set Bus command
        wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx110));

        // Wait for interrupt or until DON bit of CMDR reads '1'
        wait_till_DON();

        // Write byte “xxxxx100” to the CMDR. This is Start command
        wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx100));

        // Wait for interrupt or until DON bit of CMDR reads '1'
        wait_till_DON();




        //////////////////////////////////////////////////////
        wb_bus.master_read( .addr(2'd2), .data(data) );
        ASSERT_START: assert( data == 8'b10000100)
        else begin
            
            ncsu_error("ASSERT_START","WB START cmd failed");
        end
        ////////////////////////////////////////////////////////





        // Write byte 0x89 to the DPR. This is the slave address 0x44 shifted 1 bit to the left +
        // rightmost bit is '1' which means reading
        wb_bus.master_write(.addr(2'd1),.data(8'h45));

        //Write byte “xxxxx001” to the CMDR. This is Write command.
        wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx001));

        //Wait for interrupt or until DON bit of CMDR reads '1'.
        wait_till_DON();

       //->i2c_event; //i2c_monitor

        //////////////////// DATA RECIEVE /////////////////////////////////
        //Write byte “xxxxx010” to the CMDR. This is Read With Ack command.
        for(int i=0; i<bytes_to_transact-1; i++)begin
            //Write byte “xxxxx010” to the CMDR. This is Read With Ack command.
            wb_bus.master_write(.addr(2'd2), .data(8'b00000010));

            //Wait for interrupt or until DON bit of CMDR reads '1'.
            wait_till_DON();

            //Read DPR to get received byte of data. 
            wb_bus.master_read(.addr(2'd1), .data(read_data_from_slave[i]));
            // $display("##################################################");
            // $display(" CURRENT BYTE CAPTURE:%d", read_data_from_slave[i]); 
            // $display("##################################################");
            ->i2c_event; //i2c_monitor 
            $display("wb data received: %d",read_data_from_slave[i]);
        end

        //Read last byte with NACK telling SLAVE to stop and release the bus back to the master
        //Write byte “xxxxx011” to the CMDR. This is Read command with NACK
        wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx011) );

        //wait for interrupt or until DON bit of CMDR reads 1
        wait_till_DON();
        // READ data from DPR
        wb_bus.master_read(.addr(2'd1), .data( read_data_from_slave[bytes_to_transact-1]) );

        ->i2c_event; //i2c_monitor
        $display("wb data received: %d",read_data_from_slave[bytes_to_transact-1]);

        // $display("##################################################");
        // $display(" LAST BYTE CAPTURED:%d", read_data_from_slave[bytes_to_transact-1]); 
        // $display("##################################################");
        //////////////////////////////////////////////////////////////////

        //Write byte “xxxxx101” to the CMDR. This is Stop command.
        wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx101));

        //Wait for interrupt or until DON bit of CMDR reads '1'.
        wait_till_DON();  




        ///////////////////////////////
        wb_bus.master_read(.addr(2'd2), .data(data));
        ASSERT_STOP:assert(data == 8'b10000101)
        else begin
            ncsu_error("ASSERT STOP", "WB Stop cmd failed");
        end
        ///////////////////////////////




        //->i2c_event; //i2c_monitor
        
    endtask : wb_master_reads
    /////////////////////////////////////////////////////////////////////////////////////////////








    //////////////////////////////////////////////////////////////////////////////////////////
    task wait_till_DON();
        cmdr = 8'd0;
        //while(!irq)@(posedge clk);
        //while(cmdr == 8'd0)
        wb_bus.wait_for_interrupt();
        wb_bus.master_read(.addr(2'd2), .data(cmdr));
        //$display("Wishbone DON bit/irq status");
        casex (cmdr)
            8'b1xxxxxxx:begin end
            8'bx1xxxxxx:begin $display("slave did not respond. CMDR val: %08b | time: %0t \n", cmdr, $realtime); end
            8'bxx1xxxxx:begin $display("Arbitration Lost. CMDR val: %08b | time: %0t \n", cmdr, $realtime); end
            8'bxxx1xxxx:begin $display("ERROR. CMDR val: %08b | time: %0t", cmdr, $realtime); end
            default: begin $display("command unsuccessful. CMDR Val: %08b | time: %0t \n", cmdr, $realtime); end
        endcase
    endtask : wait_till_DON
    /////////////////////////////////////////////////////////////////////////////////////////////






endclass //wb_driver extends superClass