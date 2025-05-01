package wb_pkg;
    import ncsu_pkg::*;
    // import makes the class definitions available in the scope of this package.
    // include - is like literally copying and pasting the code.
    `include "src/wb_parameters.svh";
    `include "src/wb_configuration.svh";
    `include "src/wb_transaction.svh";
    `include "src/wb_driver.svh";
    `include "src/wb_monitor.svh";
    `include "src/wb_coverage.svh";
    `include "src/wb_agent.svh";
    //`include "src/wb_if.sv";
    // not including wb_if bcz it is compiled first in its makefile. so it will be available in simulator's compilation
    // unit, so it can be directly referenced in top module.     
endpackage