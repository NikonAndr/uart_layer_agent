class uart_test extends uvm_test;
    `uvm_component_utils(uart_test)

    my_env env;
    test_sequence_A1 seq_A1;
    test_sequence_A2 seq_A2;

    function new(string name = "uart_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = my_env::type_id::create("env", this);

        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.A1", "is_active", UVM_ACTIVE);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "env.A2", "is_active", UVM_ACTIVE);
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        
        seq_A1 = test_sequence_A1::type_id::create("seq_A1");
        seq_A2 = test_sequence_A2::type_id::create("seq_A2");

        phase.raise_objection(this);
        fork
            seq_A1.start(env.A1.sequencer);
            seq_A2.start(env.A2.sequencer);
        join
        

        #500us;
        phase.drop_objection(this);
    endtask : run_phase
endclass : uart_test 

