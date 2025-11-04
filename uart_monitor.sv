class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if.monitor vif;
    uart_agent_config cfg;

    time half_bit;

    typedef enum {WAIT_CMD, WAIT_ADDR, WAIT_DATA} monitor_state_e;
    monitor_state_e slave_state;

    uvm_analysis_port #(uart_transaction) slave_ap;
    uvm_analysis_imp #(uart_transaction, uart_monitor) monitor_tx_imp;

    uart_transaction master_queue[$];
    bit got_read_cmd;

    process p_monitor;
    process p_reset;

    function new(string name = "uart_monitor", uvm_component parent);
        super.new(name, parent);
        slave_ap = new("slave_ap", this);
        monitor_tx_imp = new("monitor_tx_imp", this);
    endfunction

    virtual function void write(uart_transaction uart_tr);
        uart_transaction uart_tr_clone;
        uart_tr_clone = uart_transaction::type_id::create("uart_tr_clone");
        uart_tr_clone = uart_tr;

        if (uart_tr.ft == FRAME_CMD && uart_tr.data[0] == 1'b0) begin
            got_read_cmd = 1'b1;
        end 

        if (got_read_cmd && uart_tr.ft == FRAME_ADDR) begin
            master_queue.push_back(uart_tr_clone);
            got_read_cmd = 1'b0;
        end
    endfunction : write

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.monitor)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "uart_monitor couldn't retrieve vif from cfg_db")
        end

        if (!uvm_config_db#(uart_agent_config)::get(this, "", "agent_config", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_monitor couldn't retrieve cfg from cfg_db")
        end

        half_bit = (cfg.var_ps * 1ps) / 2;

        slave_state = WAIT_CMD;
        got_read_cmd = 1'b0;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            fork 
            begin : drive
                p_monitor = process::self();
                if (cfg.is_master) begin
                    master_thread();
                end
                else begin
                    slave_thread();
                end 
            end 

            begin : reset
                p_reset = process::self();
                handle_reset();
            end
            join_any
            disable fork;

            if ((p_monitor != null) && (p_monitor.status == process::RUNNING)) p_monitor.kill();
            if ((p_reset != null) && (p_reset.status == process::RUNNING)) p_reset.kill();

            @(negedge vif.rst);
        end 
    endtask : run_phase

    task handle_reset();
        forever begin
            @(posedge vif.rst);

            slave_state = WAIT_CMD;
            master_queue.delete();
            got_read_cmd = 1'b0;
        end
    endtask : handle_reset

    task master_thread();
        uart_transaction uart_tr;
        byte addr;
        byte data;

        forever begin
            wait (vif.rst == 1'b0);
            wait (master_queue.size() > 0);

            capture_uart_frame(uart_tr);
            uart_tr.ft = FRAME_DATA;

            `uvm_info("MONITOR MASTER DBG", $sformatf("master queue addr %s", master_queue[0].conv2str()), UVM_HIGH)

            addr = master_queue.pop_front().data;
            data = uart_tr.data;

            `uvm_info("MONITOR_MASTER", $sformatf("reg_model_master value updated 0x%00h.0x%00h", addr, data), UVM_MEDIUM)
            
        end 
    endtask : master_thread

    task slave_thread();
        uart_transaction uart_tr;
        bit is_write;
        byte addr;
        byte data;

        forever begin
            wait (vif.rst == 1'b0);

            case (slave_state)
                WAIT_CMD : begin
                    capture_uart_frame(uart_tr);
                    uart_tr.ft = FRAME_CMD;

                    if (uart_tr.ft != FRAME_CMD) begin 
                            `uvm_error("WRONG_FRAME", $sformatf("expected FRAME_CMD, got %s", uart_tr.ft.name()))
                            continue;
                    end

                    is_write = uart_tr.data[0];
                    slave_ap.write(uart_tr);
                    slave_state = WAIT_ADDR;
                end
                WAIT_ADDR : begin
                    capture_uart_frame(uart_tr);
                    uart_tr.ft = FRAME_ADDR;

                    if (uart_tr.ft != FRAME_ADDR) begin 
                            `uvm_error("WRONG_FRAME", $sformatf("expected FRAME_ADDR, got %s", uart_tr.ft.name()))
                            continue;
                    end

                    if (is_write) begin
                        addr = uart_tr.data;
                    end

                    slave_ap.write(uart_tr);
                    slave_state = (is_write) ? WAIT_DATA : WAIT_CMD;
                end
                WAIT_DATA : begin
                    capture_uart_frame(uart_tr);
                    uart_tr.ft = FRAME_DATA;

                    if (uart_tr.ft != FRAME_DATA) begin 
                            `uvm_error("WRONG_FRAME", $sformatf("expected FRAME_DATA, got %s", uart_tr.ft.name()))
                            continue;
                    end

                    data = uart_tr.data;
                    `uvm_info("MONITOR_SLAVE", $sformatf("reg_model_slave updated 0x%00h.0x%00h", addr, data), UVM_MEDIUM)

                    slave_ap.write(uart_tr);
                    slave_state = WAIT_CMD;
                end 
            endcase
        end 
    endtask : slave_thread

    task capture_uart_frame(ref uart_transaction uart_tr);
        wait (vif.rx == 1'b0);
        uart_tr = uart_transaction::type_id::create("uart_tr");

        #half_bit;
        uart_tr.start_bit = vif.rx;
        #half_bit;

        for(int i = 0; i < 8; i++) begin
            #half_bit;
            uart_tr.data[i] = vif.rx;
            #half_bit;
        end

        #half_bit;
        uart_tr.parity_bit = vif.rx;
        #half_bit;

        #half_bit;
        uart_tr.stop_bit = vif.rx;

        `uvm_info("DEBUG MONITOR", $sformatf("monitor captured %s", uart_tr.conv2str()), UVM_HIGH)
    endtask : capture_uart_frame
endclass : uart_monitor




