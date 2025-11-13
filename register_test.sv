class register_test extends uvm_test;
    `uvm_component_utils(register_test)

    my_env env;
    register_test_sequence seq;
    slave_response_sequence slave_seq;

    function new(string name = "register_test", uvm_component parent);
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
        
        seq = register_test_sequence::type_id::create("seq");
        slave_seq = slave_response_sequence::type_id::create("slave_seq");

        phase.raise_objection(this);
        fork
            begin
                seq.start(env.reg_master_agent.reg_sequencer);
                #500us;
            end
            begin 
                #900us;
                slave_seq.start(env.A2.sequencer);
                #500us;
            end
        join
        
        phase.drop_objection(this);
    endtask : run_phase
endclass : register_test 

