class i2cmb_generator_random_test extends generator;

    wb_agent p0_agent;
    i2c_agent p1_agent;



    function new();
        super.new(name,parent);
    endfunction //new()

    // set current agent
    function void set_agent(wb_agent p0_agent, i2c_agent p1_agent);
        this.p0_agent = p0_agent;
        this.p1_agent = p1_agent;
    endfunction
    ////////////////////////////////////////////////////////////////////////


    virtual task run();

    endtask

endclass //generator_random extends generator