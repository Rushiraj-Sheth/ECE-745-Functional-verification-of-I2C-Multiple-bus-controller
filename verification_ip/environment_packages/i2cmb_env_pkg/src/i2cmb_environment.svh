class environment extends ncsu_component#(.T(ncsu_transaction));
    
    //agent, predictor, coverage, scoreboard
    wb_agent p0_agent;
    i2c_agent p1_agent;
    predictor pred;
    coverage coverage;
    scoreboard scbd;
    env_configuration configuration;
    event i2c_event;


    // test class's parent is of ncsu_transac type. so, the parent received here
    // cannot be of wb_transac type.
    function new(string name="", ncsu_component #(T) parent=null);
        super.new(name,parent);
        //ncsu_info("env::new()",$sformatf("ID: %s",get_full_name()),NCSU_MEDIUM);
    endfunction //new()


    function void set_configuration(env_configuration cfg);
        configuration = cfg;
    endfunction


    virtual function void build();
        //ncsu_info("env::build()",$sformatf("ID: %s",get_full_name()),NCSU_MEDIUM);
        super.build();
        // build wb_agent
        p0_agent = new("wb_agent",this);
        p0_agent.set_configuration(configuration.wb_agent_config);
        //send event handle
        p0_agent.set_event(i2c_event);
        p0_agent.build();


        // build i2c_agent
        p1_agent = new("i2c_agent", this);
        p1_agent.set_configuration(configuration.i2c_agent_config);
        //send the event handle first
        p1_agent.set_event(i2c_event);
        p1_agent.build();

        // predictor
        pred = new("predictor", this);
        pred.set_configuration(configuration);
        
        // scoreboard
        scbd = new("scoreboard", this);

        //coverage
        coverage = new("coverage", this);
        coverage.set_configuration(configuration);

        ///////////

        // connect predictor, coverage to wb_agent
        p0_agent.connect_subscriber(pred);
        ncsu_info("connected subscriber",$sformatf("%s. Predictor to WB Agent",pred.get_full_name()), NCSU_MEDIUM);

        // pass scoreboard instance handle to predictor. connect it to scoreboard
        pred.set_scoreboard(scbd);
        ncsu_info("connected subscriber",$sformatf("%s. Scoreboard to Predictor",scbd.get_full_name()), NCSU_MEDIUM);

        p0_agent.connect_subscriber(coverage);
        ncsu_info("connected subscriber",$sformatf("%s. Coverage to WB Agent",coverage.get_full_name()), NCSU_MEDIUM);

        // connect scoreboard to i2c_agent
        p1_agent.connect_subscriber(scbd);
        ncsu_info("connected subscriber",$sformatf("%s. Scoreboard to I2C Agent",scbd.get_full_name()), NCSU_MEDIUM);
    endfunction

    // methods to access agents. not necessary
    function ncsu_component #(T) get_wb_agent();
        return p0_agent;
    endfunction

    function ncsu_component #(T) get_i2c_agent();
        return p1_agent;
    endfunction

    // start monitor of agents
    virtual task run();
        p0_agent.run();
        p1_agent.run();
    endtask //

endclass //environment extends ncsu_component #(.T(wb_transaction))