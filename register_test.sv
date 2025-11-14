class register_test extends uvm_test;
    `uvm_component_utils(register_test)

    my_env env;

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
        uvm_status_e status;
        uvm_reg_data_t w0, w1, r0, r1;

        super.run_phase(phase);
        phase.raise_objection(this);

        //Generate 2 Random values to write 
        w0 = $urandom_range(0, 255);
        w1 = $urandom_range(0, 255);

        //Perform Write Operation on R1 & R2 regs
        env.reg_model_master.R1.write(status, w0);
        env.reg_model_master.R2.write(status, w1);
        
        //Read from R1 & R2 regs 
        //Value of R2 should stay 0xA, R2 is RO
        env.reg_model_master.R1.read(status, r0);
        env.reg_model_master.R2.read(status, r1);
        //wait for the last callback
        #1;

        //Test Log 
        `uvm_info("TEST", $sformatf("Write 0x%00h to R1, 0x%00h to R2, Read 0x%00h from R1, 0x%00h from R2",
            w0, w1, r0, r1), UVM_MEDIUM)

        phase.drop_objection(this);
    endtask : run_phase
endclass : register_test 

