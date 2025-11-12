package tb_pkg;
    timeunit 1ps; timeprecision 1ps;
    import uvm_pkg::*;
    
    `include "uvm_macros.svh"

    `include "uart_transaction.sv"
    `include "test_sequence.sv"
    `include "uart_agent_config.sv"

    typedef uvm_sequencer#(uart_transaction) uart_sequencer;
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"

    `include "register_transaction.sv"
    `include "register_monitor.sv"
    `include "register_agent.sv"
    `include "register_subscriber.sv"

    `include "my_env.sv"
    `include "uart_test.sv"

endpackage