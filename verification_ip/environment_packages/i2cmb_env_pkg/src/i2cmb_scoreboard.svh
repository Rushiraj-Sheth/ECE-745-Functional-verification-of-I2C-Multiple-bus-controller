class scoreboard extends ncsu_component #(.T(ncsu_transaction));
    T expected_trans;
    T trans_out;

    function new(string name="", ncsu_component #(T) parent=null);
        super.new(name,parent);
        super.build();
    endfunction //new()

    //receive transac from predictor
    virtual function void nb_transport(input T input_trans, output T output_trans);
        this.expected_trans = input_trans;
        // ncsu_info("scoreboard::nb_transport()",$sformatf("expected_trans: %s",expected_trans.convert2string() ),
        //             NCSU_MEDIUM );
        output_trans = this.trans_out;
        super.nb_transport(input_trans, output_trans);
    endfunction

    virtual function void nb_put(T trans);
        super.nb_put(trans);
        // ncsu_info("scoreboard::nb_put()",$sformatf("expected_trans: %s",expected_trans.convert2string() ),
        //             NCSU_MEDIUM );
        // ncsu_info("scoreboard::nb_put()",$sformatf("actual_trans: %s",trans.convert2string() ),
        //             NCSU_MEDIUM );
        // if( this.expected_trans.compare(trans) )begin
        //     $display("%s. Transaction match",get_full_name());
        // end            
        // else begin
        //     $display("%s. Transaction does not match", get_full_name());
        // end
    endfunction

    

endclass //scoreboard extends ncsu_component #(.T(wb_transaction))