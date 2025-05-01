class i2c_configuration extends ncsu_configuration;


    bit [I2C_ADDR_WIDTH-1:0] slave_addr;


    function new(string name="");
        super.new(name);
        //i2c_configuration_cg = new;
    endfunction //new()


    function void sample_coverage();
        //i2c_configuration_cg.sample();
    endfunction


    virtual function string convert2string();
        return $sformatf("name: %s ",name);
    endfunction

    //Implement slave address registering
    virtual function void store_slave_addr( bit [I2C_ADDR_WIDTH-1:0] slave_addr);
        this.slave_addr = slave_addr;
    endfunction

endclass //i2c_configuration extends ncsu_configuration