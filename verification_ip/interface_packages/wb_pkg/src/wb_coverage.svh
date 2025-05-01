class wb_coverage extends ncsu_component #(.T(ncsu_transaction));

    wb_transaction trans;


    covergroup wb_coverage_cg;
        option.per_instance = 1;
        option.name = name;

        REG_ADDR: coverpoint trans.slave_addr{
            bins cmdr = {'d2};
            bins dpr = {'d1};
        }

        DATA_RANGE: coverpoint trans.monitered_wb_data{
            bins data_range = { [0:63], [64:127] };
        }

        DATA: cross REG_ADDR,DATA_RANGE{
            bins data =  binsof(REG_ADDR.dpr) && binsof(DATA_RANGE.data_range) ;
            ignore_bins ignore =  binsof(REG_ADDR.cmdr) ;
        }
    endgroup


    function new(string name="", ncsu_component #(T) parent = null);
        super.new(name,parent);
        wb_coverage_cg = new;
    endfunction //new()


    virtual function void build();
        super.build();
    endfunction


    virtual function void nb_put(input T trans);
        //this.trans = trans;
        $cast(this.trans,trans);
        // sample the coverpoints
        wb_coverage_cg.sample();
    endfunction

endclass //wb_coverage extends superClass