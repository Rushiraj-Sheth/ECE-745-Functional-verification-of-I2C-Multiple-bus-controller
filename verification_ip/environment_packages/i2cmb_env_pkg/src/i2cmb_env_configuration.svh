class env_configuration extends ncsu_configuration;

    // define covergroup
    bit loopback;
    bit invert;
    bit [3:0] port_delay;

    covergroup env_configuration_cg;
        option.per_instance = 1;
        option.name = name;
        coverpoint loopback;
        coverpoint invert;
        coverpoint port_delay;
    endgroup

    function void sample_coverage();
        //env_configuration_cg.sample();
    endfunction

    //env_configuration sets up/instantiates configuration of both interfaces
    i2c_configuration i2c_agent_config;
    wb_configuration wb_agent_config;

    function new(string name="");
        super.new(name);
        //env_configuration_cg = new;

        i2c_agent_config = new("i2c_agent_config");
        wb_agent_config  = new("wb_agent_config");
        ncsu_info("env_config::new()",$sformatf("ID: %s",this.convert2string()),NCSU_MEDIUM);
        $display("%s",wb_agent_config.convert2string());
        $display("%s",i2c_agent_config.convert2string());


        // sample configs of I2C and WB
        i2c_agent_config.sample_coverage();
        wb_agent_config.sample_coverage();        
    endfunction //new()


    //can implement slave address and bus_num storage
    // these can be accessed from test class
       
endclass //env_configuration extends ncsu_configuration