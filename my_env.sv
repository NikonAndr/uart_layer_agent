class my_env extends uvm_env;
    `uvm_component_utils(my_env)

    uart_agent A1;
    uart_agent A2;

    register_agent reg_master_agent;
    register_agent reg_slave_agent;

    register_subscriber reg_sub;

    register_block reg_model_master;
    register_block reg_model_slave;

    register_adapter adapter;
    register_predictor slave_predictor;

    function new(string name = "uart_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        A1 = uart_agent::type_id::create("A1", this);
        A2 = uart_agent::type_id::create("A2", this);

        reg_master_agent = register_agent::type_id::create("reg_master_agent", this);
        reg_slave_agent = register_agent::type_id::create("reg_slave_agent", this);

        reg_sub = register_subscriber::type_id::create("reg_sub", this);

        //reg_model_master creation & configuration
        reg_model_master = register_block::type_id::create("reg_model_master");
        reg_model_master.build();
        reg_model_master.reset();
        reg_model_master.default_map.set_auto_predict(1);

        //reg_model_slave creation & configuration
        reg_model_slave = register_block::type_id::create("reg_model_slave");
        reg_model_slave.build();
        reg_model_slave.reset();
        reg_model_slave.default_map.set_auto_predict(0);

        //pass reg_model_slave to slave_responder
        uvm_config_db#(register_block)::set(this, "reg_slave_agent.slave_responder", "reg_model", reg_model_slave);

        //create reg_adapter
        adapter = register_adapter::type_id::create("adapter");

        //create slave_predictor 
        slave_predictor = register_predictor::type_id::create("slave_predictor", this);
    endfunction : build_phase

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        //handles to sequencers
        reg_master_agent.driver.uart_master_sequencer = A1.sequencer;
        reg_slave_agent.slave_responder.uart_slave_sequencer = A2.sequencer;

        //slave predictor setup
        slave_predictor.map = reg_model_slave.default_map;
        slave_predictor.adapter = adapter;

        reg_slave_agent.monitor.reg_monitor_ap.connect(slave_predictor.bus_in);

        //master frontdoor 
        reg_model_master.default_map.set_sequencer(reg_master_agent.reg_sequencer, adapter);
        
        //TLM connections
        //UART SLAVE MONITOR -> REG MONITOR
        A2.monitor.uart_slave_ap.connect(reg_slave_agent.monitor.uart_slave_imp);

        //UART MASTER MONITOR -> REG DRIVER
        A1.monitor.uart_master_ap.connect(reg_master_agent.driver.uart_master_imp);

        //REG MONITOR -> REG SUBSCRIBER
        reg_slave_agent.monitor.reg_monitor_ap.connect(reg_sub.analysis_export);

        //REG MONITOR -> SLAVE RESPONDER
        reg_slave_agent.monitor.reg_monitor_ap.connect(reg_slave_agent.slave_responder.reg_monitor_imp);
    endfunction : connect_phase
endclass : my_env