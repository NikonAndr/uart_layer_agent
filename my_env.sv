class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    uart_agent A1;
    uart_agent A2;

    function new(string name = "uart_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        A1 = uart_agent::type_id::create("A1", this);
        A2 = uart_agent::type_id::create("A2", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        A1.driver.master_ap.connect(A1.monitor.monitor_tx_imp);
        A2.monitor.slave_ap.connect(A2.driver.driver_rx_imp);
    endfunction : connect_phase
endclass : my_env