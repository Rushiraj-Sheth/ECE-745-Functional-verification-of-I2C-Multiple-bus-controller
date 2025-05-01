class i2c_agent extends ncsu_component#(.T(ncsu_transaction));

    i2c_configuration configuration;
    i2c_driver driver;
    i2c_monitor monitor;
    ncsu_component #(T) subscribers[$]; // components conneted to this agent
    virtual i2c_if bus; 
    event i2c_event;
    i2c_coverage i2c_cg;

    function new(string name="",ncsu_component #(T) parent = null);
        super.new(name,parent);  
        //we need to retrieve i2c handle from config db. it is allowed bcz its methods are static 
        if( !( ncsu_config_db #(virtual i2c_if)::get(get_full_name(),this.bus) ) )begin
            //fatal error bcz requested handle not found
            //ncsu_info();
            ncsu_fatal("i2c_agent::new().", $sformatf(" I2C_if handle not found. ID: %s",get_full_name()) );
        end
        //ncsu_info("i2c_agent::build()",$sformatf("ID: %s",get_full_name()),NCSU_MEDIUM);     
    endfunction //new()

    function void set_configuration(i2c_configuration cfg);
        configuration = cfg;
    endfunction

    function void set_event(event ev);
        this.i2c_event = ev;
    endfunction

    virtual function void build();
        //ncsu_info("i2c_agent::build()",$sformatf("ID: %s",get_full_name()),NCSU_MEDIUM);
        super.build();
        //build driver
        driver = new("driver",this);
        driver.set_configuration(configuration);
        driver.i2c_bus = this.bus; // pass the handle of i2c_if


        //monitor
        monitor = new("monitor", this);
        monitor.set_configuration(configuration);
        monitor.i2c_bus = this.bus;
        monitor.i2c_event = this.i2c_event;

        // build i2c coverage
        i2c_cg = new("i2c_coverage", this);
        i2c_cg.build();
        this.connect_subscriber(i2c_cg);
    endfunction

    virtual task bl_put(T trans);
        driver.bl_put(trans);
    endtask

    virtual task run();
        fork
            monitor.run();
        join_none
    endtask 

    // list of components connected to i2c_agent
    virtual function void connect_subscriber(ncsu_component#(T) subscriber);
        subscribers.push_back(subscriber);
    endfunction

    // method to send transaction from this agent to each connected component
    virtual function void nb_put(T trans);
        foreach(subscribers[i]) subscribers[i].nb_put(trans);
    endfunction


endclass //i2c_agent extends ncsu_component#(.T(ncsu_transaction))