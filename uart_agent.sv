class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)

    virtual uart_if vif;
    uart_agent_config cfg;

    uart_driver driver;
    uart_monitor monitor;
    uart_sequencer sequencer;

    function new(string name = "uart_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "uart_agent couldn't retrieve vif from cfg_db")
        end

        if (!uvm_config_db#(uart_agent_config)::get(this, "", "uart_agent_config", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_agent couldn't retrieve cfg from cfg_db")
        end

        if (!uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active)) begin
            `uvm_fatal("NO_AGENT_STATUS", "uart_agent status is not set")
        end

        if (get_is_active() == UVM_ACTIVE) begin
            driver = uart_driver::type_id::create("driver", this);
            sequencer = uart_sequencer::type_id::create("sequencer", this);

            uvm_config_db#(virtual uart_if.driver)::set(this, "driver", "vif", vif.driver);
            uvm_config_db#(uart_agent_config)::set(this, "driver", "agent_config", cfg);
        end 

        monitor = uart_monitor::type_id::create("monitor", this);
        
        uvm_config_db#(virtual uart_if.monitor)::set(this, "monitor", "vif", vif.monitor);
        uvm_config_db#(uart_agent_config)::set(this, "monitor", "agent_config", cfg);
    endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction : connect_phase
endclass : uart_agent