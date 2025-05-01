class wb_configuration extends ncsu_configuration;

    function new(string name="");
        super.new(name);
      //  wb_configuration_cg = new;
    endfunction //new()

 

    function void sample_coverage();
       // wb_configuration_cg.sample();
    endfunction

    virtual function string convert2string();
        return {super.convert2string()};
    endfunction

endclass //wb_configuration extends ncsu_configuration