class register_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(register_scoreboard)

    register_block reg_model_master;
    register_block reg_model_slave;

    int matches_count;
    int mismatches_count;

    bit in_reset;

    function new(string name = "register_scoreboard", uvm_component parent);
        super.new(name, parent);
        matches_count = 0;
        mismatches_count = 0;
        in_reset = 0;
    endfunction

    function void compare_all_registers();
        byte master_r1, master_r2;
        byte slave_r1, slave_r2;

        master_r1 = reg_model_master.R1.get_mirrored_value();
        master_r2 = reg_model_master.R2.get_mirrored_value();

        slave_r1 = reg_model_slave.R1.get_mirrored_value();
        slave_r2 = reg_model_slave.R2.get_mirrored_value();

        if (master_r1 == slave_r1 && master_r2 == slave_r2) begin
            `uvm_info("SCOREBOARD", $sformatf("MATCH: Master[R1=0x%0h R2=0x%0h] SLAVE[R1=0x%0h R2=0x%0h]",
                master_r1, master_r2, slave_r1, slave_r2), UVM_MEDIUM)
            matches_count++;
        end else begin
            `uvm_info("SCOREBOARD", $sformatf("MISMATCH: Master[R1=0x%0h R2=0x%0h] SLAVE[R1=0x%0h R2=0x%0h]",
                master_r1, master_r2, slave_r1, slave_r2), UVM_MEDIUM)
            mismatches_count++;
        end
    endfunction : compare_all_registers;

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCOREBOARD", $sformatf("TOTAL MATCHES: %0d", matches_count), UVM_LOW)
        `uvm_info("SCOREBOARD", $sformatf("TOTAL MISMATCHES: %0d", mismatches_count), UVM_LOW)
    endfunction : report_phase

endclass : register_scoreboard

//callback for a scoreboard
class register_scoreboard_cb extends uvm_reg_cbs;
    `uvm_object_utils(register_scoreboard_cb)

    register_scoreboard scoreboard;

    function new(string name = "register_scoreboard_cb");
        super.new(name);
    endfunction 

    virtual function void post_predict(
        input uvm_reg_field fld,
        input uvm_reg_data_t previous,
        inout uvm_reg_data_t value,
        input uvm_predict_e kind,
        input uvm_path_e path,
        input uvm_reg_map map
    );
        //don't compare during reset
        if (scoreboard.in_reset) begin
            `uvm_info("SCOREBOARD_CB", "skipping - reset active", UVM_HIGH)
            return;
        end

        fork
            begin
                #1;
                scoreboard.compare_all_registers();
            end
        join_none
    endfunction : post_predict
endclass : register_scoreboard_cb
