class register_agent extends uvm_agent;
    `uvm_component_utils(register_agent)

    virtual uart_if vif;

    register_agent_config cfg;
    register_driver driver;
    register_monitor monitor;
    register_sequencer reg_sequencer;
    register_slave_responder slave_responder;


    function new(string name = "register_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "register_agent couldn't retrieve vif")
        end

        if (!uvm_config_db#(register_agent_config)::get(this, "", "register_agent_config", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "register_agent couldn't get register_config from cfg db")
        end

        if (cfg.is_master) begin
            driver = register_driver::type_id::create("driver", this);
            reg_sequencer = register_sequencer::type_id::create("sequencer", this);

            uvm_config_db#(virtual uart_if.reset_only)::set(this, "driver", "vif", vif.reset_only);
            uvm_config_db#(register_agent_config)::set(this, "driver", "register_agent_config", cfg);
        end
        else begin
            monitor = register_monitor::type_id::create("monitor", this);
            slave_responder = register_slave_responder::type_id::create("slave_responder", this);

            uvm_config_db#(virtual uart_if.reset_only)::set(this, "monitor", "vif", vif.reset_only);
            uvm_config_db#(virtual uart_if.reset_only)::set(this, "slave_responder", "vif", vif.reset_only);
        end   
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (cfg.is_master) begin
            driver.seq_item_port.connect(reg_sequencer.seq_item_export);
        end
    endfunction : connect_phase
endclass : register_agent