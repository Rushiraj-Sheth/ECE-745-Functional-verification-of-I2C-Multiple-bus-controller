//i2c package
package i2c_pkg;

// QUESTION: Why path to ncsu package is not provided below? (Bcz they are not at same hierarchy)

// ############### SOLUTION 1: ###############################################################
// In SystemVerilog, once a package is compiled, its definitions are available globally in the 
// scope of the simulator. This means: If ncsu_pkg.sv was compiled before i2c_pkg.sv, 
// then ncsu_pkg is already available and does not need a file path.
// The simulator treats compiled packages like a global symbol table—once loaded, 
// they can be accessed from anywhere via import.

// ############# SOLUTION 2: ##################################################################
// The +incdir+ or Compilation File List in Tool Setup
// Many simulation tools (like Questa, VCS, Xcelium) allow specifying an 
// include directory (+incdir+ option) or a file list to locate files automatically.
// ############################################################################################
import ncsu_pkg::*;

`include "src/i2c_parameters.svh";
`include "src/i2c_configuration.svh";
`include "src/i2c_transaction.svh";
`include "src/i2c_driver.svh";
`include "src/i2c_monitor.svh";
`include "src/i2c_coverage.svh";
`include "src/i2c_agent.svh";
//`include "src/i2c_if.sv";
//SystemVerilog interfaces (interface blocks) do not necessarily need to be inside a package.
//If i2c_if.sv was compiled separately and made available in the simulator's compilation unit, 
//it can still be referenced in top.sv, even if it’s not explicitly included inside i2c_pkg


endpackage