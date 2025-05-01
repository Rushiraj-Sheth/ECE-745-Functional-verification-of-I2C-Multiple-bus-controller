
class verif_test extends ncsu_component#(.T(ncsu_transaction));
    
    virtual interface wb_if wb_bus;
    bit avail = 1'd0;

    function new(string name="", ncsu_component #(T) parent=null);
        super.new(name,parent);

        // get_full_name() --> verif_wb_bus, verif_i2c_bus

        avail = ncsu_config_db#(virtual interface wb_if)::get(get_full_name(),this.wb_bus);
        if(!avail)begin
            ncsu_fatal("verif_test::new()", $sformatf("virtual handle not found. ID: %s", get_full_name()) );
        end
    endfunction //new()


    virtual task run();

            
            bit [7:0] data;

            // core enable/disable test
            wb_bus.master_write(.addr(2'b00),.data(8'b00000000));
            wb_bus.master_write(.addr(2'b00),.data(8'b11000000));
            wb_bus.master_read(.addr(2'b00),.data(data));
            ASSERT1: assert( data == 8'b11000000 )begin
                $display("I2CMB Core enable - SUCCESS!");
            end
            else begin
                $display("%08b",data);
                ncsu_error("ASSERT1", "I2CMB Core enable test failed.");
            end
            /////////////////////////////////////////////

            wb_bus.master_write(.addr(2'b00),.data(8'b00000000));
            wb_bus.master_read(.addr(2'b00),.data(data));
            ASSERT2: assert( data == 8'b00000000 )begin
                $display("ASSERT2: I2CMB Core disable/reset - Success");
            end
            else begin
                ncsu_error("ASSERT2", "I2CMB Core disable test failed");
            end
            /////////////////////////////////////////////


            ////////////////////////////////////////////////////////////////////////////////////////
            // all WB Registers have default values
            ////////// 1. CSR 
            wb_bus.master_read(.addr(2'b00),.data(data));
            def1: assert( data == 8'b00000000 )begin
                $display("def1: CSR default value test - Success");
            end
            else begin
                ncsu_error("def1", "CSR initialised to default value - assert failed");
            end
            /////////////////////// CSR

            //////// 2. DPR
            wb_bus.master_read( .addr(2'b01),.data(data) );
            def2: assert( data == 8'b00000000 )begin
                $display("def2: DPR default value test - Success");
            end
            else begin
                ncsu_error("def2","DPR default value test - assert failed");
            end
            //////////////////////// DPR


            ////////// 3. CMDR
            wb_bus.master_read(.addr(2'd2), .data(data) );
            def3: assert( data == 8'b10000000 )begin
                $display("def3: CMDR default value test - Success");
            end
            else begin
                ncsu_error("def3","CMDR default value test - assert failed");
            end
            /////////////////////// CMDR


            ///////////// 4. FSMR
            wb_bus.master_read(.addr(2'd3), .data(data));
            def4: assert( data == 8'b00000000 )begin
                $display("def4: FSMR deafault value test - Success");
            end
            else begin
                ncsu_error( "def4", "FSMR default value test - assert failed " );
            end
            //////////////////////// FSMR 

            ////////////////////////////////////////////////////////////////////////////////////////


            ////////////////////////////////////////////////////////////////////////////////////////
            // access CSR,DPR,CMDR,FSMR by their address
            wb_bus.master_write( .addr(2'd0), .data(8'b00000000) );
            wb_bus.master_write( .addr(2'd0), .data(8'b11000000) );

            ////////// CSR
            wb_bus.master_write(.addr(2'd0),.data(8'b11111111));
            wb_bus.master_read(.addr(2'd0),.data(data));
            ASSERT_CSR: assert(data === 8'b11000000)begin
                $display(" write to Read Only bits of CSR not allowed. Test - Success");
            end
            else begin
                $display("%08b", data);
                ncsu_error("ASSERT_CSR", "Invalid write to RO bits of CSR - failed");
            end
            //////////////////////// CSR

            //////// DPR
            wb_bus.master_write(.addr(2'd1), .data(8'b11111111));
            wb_bus.master_read(.addr(2'd1),.data(data)); // return last byte received via I2C bus, default is 0
            ASSERT_DPR: assert(data == 8'b00000000)begin
                $display("DPR read/write test - Success");
            end
            else begin
                $display("%08b", data);
                ncsu_error("ASSERT_DPR","DPR Read/write test failed");
            end
            //////////////////////// DPR

            ///// CMDR
            wb_bus.master_write(.addr(2'd2),.data(8'b11111000));
            wb_bus.master_read(.addr(2'd2),.data(data));    
            ASSERT_CMDR: assert(data  === 8'b00000000)begin
                $display("write to read only bits of CMDR NOT allowed. Test - Success");
            end
            else begin
                $display("%08b", data);
                ncsu_error("ASSERT_CMDR","invalid write to CMDR read only bits. Test - failed");
            end
            ////////////////////////// CMDR

            //// FSMR
            wb_bus.master_write(.addr(2'd3),.data(8'b11111111));
            wb_bus.master_read(.addr(2'd3),.data(data));
            ASSERT_FSMR: assert( data == 8'b01110000 )begin
                $display("write to read only bits of FSMR NOT allowed. Test - Success");
            end
            else begin
                $display("%08b", data);
                ncsu_error("ASSERT_FSMR","invalid write to FSMR read only bits. Test - failed");
            end
            /////////////////////////// FSMR
            ////////////////////////////////////////////////////////////////////////////////////////
            

            ////////////////////////////////////////////////////////////////////////////////////////            
            ////// CMDR DON/irq stat
            // will issue below following commands and test the irq bit
                    // //set enable bit 1 and enable interrupt 1 in CSR
                wb_bus.master_write(.addr(2'b00),.data(8'b11xxxxxx));

                //write bus id as 0 to DPR
                wb_bus.master_write(.addr(2'b01), .data(8'd0));


                //write set bus command to CMDR
                wb_bus.master_write(.addr(2'd2), .data(8'bxxxxx110));

                //wait for interrupt or till DON bit of CMDR reads 1
                wb_bus.wait_for_interrupt();
                wb_bus.master_read( .addr(2'd2), .data(data) );
                ASSERT_IRQ: assert( data == 8'b10000000 )begin
                    $display("CMDR DON bit test - Success");
                end
                else begin
                    ncsu_error("ASSERT_IRQ","CMDR DON bit test - failed");
                end
            ///////////////
            ////////////////////////////////////////////////////////////////////////////////////////
    endtask


endclass //verif_test extends ncsu_component#(.T(ncsu_transaction))