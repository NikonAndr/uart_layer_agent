package tb_pkg;
    timeunit 1ps; timeprecision 1ps;
    import uvm_pkg::*;
    
    `include "uvm_macros.svh"

    `include "uart_transaction.sv"
    `include "test_sequence.sv"
    `include "uart_byte_sequence.sv"
    `include "uart_agent_config.sv"

    typedef uvm_sequencer#(uart_transaction) uart_sequencer;
    `include "uart_driver.sv"
    `include "uart_monitor.sv"
    `include "uart_agent.sv"

    `include "register_transaction.sv"
    `include "register_agent_config.sv"
    typedef uvm_sequencer#(register_transaction) register_sequencer;

    `include "register_monitor.sv"
    `include "register_driver.sv"

    `include "register_model.sv"
    `include "register_adapter.sv"

    `include "register_slave_responder.sv"
    `include "register_predictor.sv"
    
    `include "register_agent.sv"
    //`include "register_test_sequence.sv"

    `include "register_subscriber.sv"

    `include "my_env.sv"
    `include "register_test.sv"

endpackage