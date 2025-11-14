class register_monitor extends uvm_monitor;
    `uvm_component_utils(register_monitor)

    typedef enum {WAIT_CMD, WAIT_ADDR, WAIT_DATA} state_e;

    uvm_analysis_imp#(uart_transaction, register_monitor) uart_slave_imp;
    uvm_analysis_port#(register_transaction) reg_monitor_ap;

    state_e state;
    register_operation current_op;
    byte current_addr;

    virtual uart_if.reset_only vif;

    function new(string name = "register_monitor", uvm_component parent);
        super.new(name, parent);
        uart_slave_imp = new("uart_slave_imp", this);
        reg_monitor_ap = new("reg_monitor_ap", this);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.reset_only)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "register_monitor couldn't retrieve reset vif")
        end
        
        state = WAIT_CMD;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            @(posedge vif.rst);
            state = WAIT_CMD;

            @(negedge vif.rst);
        end
    endtask : run_phase

    virtual function void write(uart_transaction uart_tr);
        register_transaction register_tr;

        if (vif.rst) begin
              return;
        end

        case (state)
            WAIT_CMD : begin
                current_op = register_operation'(uart_tr.data[0]);

                state = WAIT_ADDR;
            end 
            WAIT_ADDR : begin 
                current_addr = uart_tr.data;

                if (current_op == REG_WRITE) begin
                    state = WAIT_DATA;
                end else begin
                    register_tr = register_transaction::type_id::create("register_transaction");
                    register_tr.op = REG_READ;
                    register_tr.addr = current_addr;

                    reg_monitor_ap.write(register_tr);
                    state = WAIT_CMD;
                end 
            end 
            WAIT_DATA : begin
                register_tr = register_transaction::type_id::create("register_tr");

                register_tr.op = REG_WRITE;
                register_tr.addr = current_addr;
                register_tr.data = uart_tr.data;

                reg_monitor_ap.write(register_tr);
                state = WAIT_CMD;
            end
        endcase 
    endfunction : write
endclass : register_monitor