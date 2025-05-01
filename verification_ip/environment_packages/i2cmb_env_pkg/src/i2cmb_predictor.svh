class predictor extends ncsu_component #(.T(ncsu_transaction));
    
    ncsu_component #(T) scoreboard;
    T transport_trans; //output of scoreboard
    env_configuration configuration;
    
    function new(string name = "", ncsu_component #(T) parent = null);
        super.new(name,parent);
        super.build();
    endfunction //new()

    function void set_configuration(env_configuration cfg);
        configuration = cfg;
    endfunction


    // receives scoreboard instance
    virtual function void set_scoreboard(ncsu_component #(T) scoreboard);
        this.scoreboard = scoreboard;
    endfunction


    // to recieve a transaction from agent
    virtual function void nb_put(T trans);
        // ncsu_info("predictor::nb_put()", $sformatf(" of %s called. Transaction is: %s"
        //             , get_full_name(), trans.convert2string() ), NCSU_MEDIUM );
        scoreboard.nb_transport(trans, transport_trans);
        super.nb_put(trans);
    endfunction

endclass //predictor extends ncsu_component #(.T(wb_transaction))