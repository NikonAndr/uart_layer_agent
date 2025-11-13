import uvm_pkg::*;
`include "uvm_macros.svh"

`include "interface.sv"
`include "tb_pkg.sv"
import tb_pkg::*;

module top;
    timeunit 1ns; timeprecision 1ps;
    uart_if vif_A1();
    uart_if vif_A2();
    uart_agent_config cfg_a1;
    uart_agent_config cfg_a2;
    register_agent_config cfg_reg_master;
    register_agent_config cfg_reg_slave;

    bit rst;

    /*initial begin
        //Reset before running program
        rst = 1'b1;
        #50ns;
        rst = 1'b0;
    end*/
    initial begin
          $dumpfile("uart_test.vcd");  // nazwa pliku
          $dumpvars(0, top);           // 0 = dump wszystko w module top
    end


    assign vif_A1.rst = rst;
    assign vif_A2.rst = rst;

    assign vif_A1.rx = vif_A2.tx;
    assign vif_A2.rx = vif_A1.tx;

    initial begin

        fork
            begin : reset_thread
                rst = 1'b1;
                #20ns;
                rst = 1'b0;
                #500us;
                //`uvm_info("TOP", "Triggering async reset mid-simulation", UVM_LOW)
                //rst = 1'b1;
                #50us;
                rst = 1'b0;
            end
            begin : uvm_thread
                //Master Agent Config 
                cfg_a1 = uart_agent_config::type_id::create("cfg_a1");
                if (!cfg_a1.randomize()) begin
                    `uvm_error("CFG", "Cfg Randomization Failed!")
                end
                cfg_a1.calculate_var_ps();
                cfg_a1.is_master = 1;
                uvm_config_db#(uart_agent_config)::set(null, "*.env.A1", "uart_agent_config", cfg_a1);

                //Slave Agent Config
                cfg_a2 = uart_agent_config::type_id::create("cfg_a2");
                //Set A2 bitrate based on A1 bitrate
                cfg_a2.bitrate = cfg_a1.bitrate;
                cfg_a2.calculate_var_ps();
                cfg_a2.is_master = 0;
                uvm_config_db#(uart_agent_config)::set(null, "*.env.A2", "uart_agent_config", cfg_a2);

                //Register Agent Master Config
                cfg_reg_master = register_agent_config::type_id::create("cfg_reg_master");
                cfg_reg_master.is_master = 1'b1;
                uvm_config_db#(register_agent_config)::set(null, "*.env.reg_master_agent", "register_agent_config", cfg_reg_master);

                //Register Agent Slave Config
                cfg_reg_slave = register_agent_config::type_id::create("cfg_reg_slave");
                cfg_reg_slave.is_master = 1'b0;
                uvm_config_db#(register_agent_config)::set(null, "*.env.reg_slave_agent", "register_agent_config", cfg_reg_slave);

                //Set Vif's for A1 & A2
                uvm_config_db#(virtual uart_if)::set(null, "*.env.A1", "vif", vif_A1);
                uvm_config_db#(virtual uart_if)::set(null, "*.env.A2", "vif", vif_A2);
                
                //Set Vif for reg_master_agent & reg_slave_agent
                uvm_config_db#(virtual uart_if)::set(null, "*.env.reg_master_agent", "vif", vif_A1);
                uvm_config_db#(virtual uart_if)::set(null, "*.env.reg_slave_agent", "vif", vif_A2);

                //Set Test Name Using +UVM_TESTNAME= 
                run_test();  
            end    
        join
    end
endmodule : top