
class test_base extends ncsu_component#(.T(ncsu_transaction));
    env_configuration cfg;
    environment env;
    generator gen;

    //i2cmb_generator_random_test gen_rand_read;  // wb writes, i2c reads
    //string gen_type;

    function new(string name="",ncsu_component#(T) parent = null);
        super.new(name,parent);
        
        // instantiate configuration of env, wb and i2c
        cfg = new("configuration");
        cfg.sample_coverage();

        // instantiates env
        env = new("env", this);
        env.set_configuration(cfg);
        env.build(); //builds driver and monitor

        // instantiate gen
        gen = new("gen",this);
        gen.set_agent(env.p0_agent, env.p1_agent);

        super.build();
    endfunction //new()

    
    virtual task run();
        env.run(); 
        // set gen transactions of both agents before gen.run()
        // taken care in derived test class
        ///////////////////////////////////////////////////////

        gen.run();
    endtask

endclass //test_base extends ncsu_component#(.T(ncsu_transaction))