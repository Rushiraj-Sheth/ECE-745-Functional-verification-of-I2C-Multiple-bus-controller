class wb_agent extends ncsu_component #(.T(ncsu_transaction) );
    //retrieve handle from configuration DB .
    //instantiate monitor and driver components
    
    wb_configuration configuration;
    wb_driver driver;
    wb_monitor monitor;
    ncsu_component#(T) subscribers[$]; //components connected to this agent
    virtual wb_if wb_bus;
    bit avail = 1'd0;

    event i2c_event;
    event wb_event;

    wb_coverage wb_cg;

    //now retrieve handle from configuration db
    function new(string name="", ncsu_component#(T) parent=null);
        super.new(name,parent);
        avail = ncsu_config_db #(virtual wb_if)::get(get_full_name(),this.wb_bus);
        if ( !avail ) begin
            ncsu_fatal("wb_agent::new().", $sformatf(" wb_if handle not found. Id: %s",get_full_name() ) );
        end
    endfunction //new()

    function void set_configuration(wb_configuration cfg);
        configuration = cfg;
    endfunction

    function void set_event(event ev);
        this.i2c_event = ev;
    endfunction

    //build driver and monitor
    virtual function void build();
        //ncsu_info("wb_agent::build()",$sformatf("ID: %s",get_full_name()),NCSU_MEDIUM);
        super.build();
        //driver
        driver = new( "driver", this );
        driver.set_configuration( configuration );
        driver.wb_bus = this.wb_bus;
        driver.i2c_event = this.i2c_event;
        driver.wb_event = this.wb_event;

        //monitor
        monitor = new( "monitor", this );
        monitor.set_configuration( configuration );
        monitor.wb_bus = this.wb_bus;
        monitor.wb_event = this.wb_event;

        // build coverage
        wb_cg = new("wb_coverage", this);
        wb_cg.build();
        this.connect_subscriber(wb_cg);
    endfunction

    virtual task bl_put(T trans);
        driver.bl_put(trans);
    endtask

    virtual task run();
        fork
            monitor.run();
        join_none
    endtask

    // list of components connected to wb_agent
    virtual function void connect_subscriber(ncsu_component#(T) subscriber);
        subscribers.push_back(subscriber);
    endfunction

    // method to send transaction from this agent to each connected component
    virtual function void nb_put(T trans);
        foreach(subscribers[i]) subscribers[i].nb_put(trans);
    endfunction

endclass //wb_agent extends superClass