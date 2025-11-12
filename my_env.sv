class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    uart_agent A1;
    uart_agent A2;
    register_agent reg_agent;
    register_subscriber reg_sub;

    function new(string name = "uart_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        A1 = uart_agent::type_id::create("A1", this);
        A2 = uart_agent::type_id::create("A2", this);
        reg_agent = register_agent::type_id::create("reg_agent", this);
        reg_sub = register_subscriber::type_id::create("reg_sub", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        A2.monitor.uart_slave_ap.connect(reg_agent.monitor.uart_slave_imp);
        reg_agent.monitor.reg_monitor_ap.connect(reg_sub.analysis_export);
    endfunction : connect_phase
endclass : my_env