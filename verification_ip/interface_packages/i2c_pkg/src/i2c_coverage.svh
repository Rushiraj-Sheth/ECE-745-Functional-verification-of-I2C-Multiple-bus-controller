class i2c_coverage extends ncsu_component #(.T(ncsu_transaction));

    i2c_transaction trans;
    bit [I2C_DATA_WIDTH-1:0] data;

    covergroup i2c_coverage_cg;
        option.per_instance =1;
        option.name = name;
        ADDR: coverpoint trans.slave_addr{
            bins addr = {8'h22}; //default slave address
        }
        OP: coverpoint trans.op{
            bins write = {0};
            bins read = {1};
        }
    endgroup

    covergroup i2c_data_coverage_cg;

        option.per_instance = 1;
        option.name = name;

        DATA: coverpoint data{
            bins values[] = { [0:127] };
        }

    endgroup

    function new(string name="", ncsu_component #(T) parent = null);
        super.new(name,parent);
        i2c_coverage_cg = new;
        i2c_data_coverage_cg = new;
    endfunction //new()

    
    virtual function void build();
        super.build();
    endfunction

    virtual function void nb_put(input T trans);
        //this.trans = trans;
        $cast(this.trans,trans);

        i2c_coverage_cg.sample();
        foreach(this.trans.data[i])begin
            this.data = this.trans.data[i];
            i2c_data_coverage_cg.sample();
        end

    endfunction

endclass //i2c_coverage extends superClass