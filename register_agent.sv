class register_agent extends uvm_agent;
    `uvm_component_utils(register_agent)

    register_monitor monitor;

    function new(string name = "register_agent", uvm_component parent);
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = register_monitor::type_id::create("monitor", this);
    endfunction : build_phase
endclass : register_agent


