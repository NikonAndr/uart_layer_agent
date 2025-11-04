class uart_driver extends uvm_driver#(uart_transaction);
    `uvm_component_utils(uart_driver)

    virtual uart_if.driver vif;
    uart_agent_config cfg;

    time full_bit;

    typedef enum  {WAIT_CMD, WAIT_ADDR, WAIT_DATA} driver_state_e;
    driver_state_e master_state;

    uvm_analysis_imp #(uart_transaction, uart_driver) driver_rx_imp;
    uvm_analysis_port #(uart_transaction) master_ap;

    uart_transaction slave_queue[$];
    bit got_read_cmd;

    process p_drive;
    process p_reset;

    function new(string name = "uart_driver", uvm_component parent);
        super.new(name, parent);
        driver_rx_imp = new("driver_rx_imp", this);
        master_ap = new("master_ap", this);
    endfunction 

    virtual function void write(uart_transaction uart_tr);
        uart_transaction uart_tr_clone;
        uart_tr_clone = uart_transaction::type_id::create("uart_tr_clone");
        uart_tr_clone = uart_tr;

        if (uart_tr.ft == FRAME_CMD && uart_tr.data[0] == 1'b0) begin
            got_read_cmd = 1'b1;
        end 

        if (got_read_cmd && uart_tr.ft == FRAME_ADDR) begin
            slave_queue.push_back(uart_tr_clone);
            got_read_cmd = 1'b0;
        end
    endfunction : write

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.driver)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "uart_driver couldn't retrieve vif from cfg_db")
        end

        if (!uvm_config_db#(uart_agent_config)::get(this, "", "agent_config", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_driver couldn't retrieve cfg from cfg_db")
        end

        full_bit = cfg.var_ps * 1ps;

        master_state = WAIT_CMD;
        got_read_cmd = 1'b0;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            fork 
            begin : drive
                p_drive = process::self();
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

            if ((p_drive != null) && (p_drive.status == process::RUNNING)) p_drive.kill();
            if ((p_reset != null) && (p_reset.status == process::RUNNING)) p_reset.kill();

            @(negedge vif.rst);
        end 
    endtask : run_phase 

    task handle_reset();
        forever begin
            @(posedge vif.rst);

            vif.tx <= 1'b1;
            slave_queue.delete();
            master_state = WAIT_CMD;
            got_read_cmd = 1'b0;
        end
    endtask : handle_reset

    task master_thread();
        uart_transaction uart_tr;
        bit is_write;

        vif.tx <= 1'bx;

        forever begin
            wait (vif.rst == 1'b0);

            case (master_state)
                WAIT_CMD : begin
                    seq_item_port.get_next_item(uart_tr);

                    if (uart_tr.ft != FRAME_CMD) begin 
                        `uvm_error("WRONG_FRAME", $sformatf("expected FRAME_CMD, got %s", uart_tr.ft.name()))
                        seq_item_port.item_done();
                        continue;
                    end

                    //drive cmd frame
                    drive_uart_frame(uart_tr);
                    is_write = uart_tr.data[0];
                    master_ap.write(uart_tr);
                    seq_item_port.item_done();

                    master_state = WAIT_ADDR;
                end
                WAIT_ADDR : begin
                    seq_item_port.get_next_item(uart_tr);

                    if (uart_tr.ft != FRAME_ADDR) begin 
                        `uvm_error("WRONG_FRAME", $sformatf("expected FRAME_ADDR, got %s", uart_tr.ft.name()))
                        seq_item_port.item_done();
                        continue;
                    end

                    //drive addr frame
                    drive_uart_frame(uart_tr);
                    master_ap.write(uart_tr);
                    seq_item_port.item_done();

                    master_state = (is_write) ? WAIT_DATA : WAIT_CMD;
                end 
                WAIT_DATA : begin
                    seq_item_port.get_next_item(uart_tr);

                    if (uart_tr.ft != FRAME_DATA) begin 
                        `uvm_error("WRONG_FRAME", $sformatf("expected FRAME_DATA, got %s", uart_tr.ft.name()))
                        seq_item_port.item_done();
                        continue;
                    end

                    //drive data frame
                    drive_uart_frame(uart_tr);
                    master_ap.write(uart_tr);
                    seq_item_port.item_done();
                    
                    master_state = WAIT_CMD;
                end
            endcase
        end
    endtask : master_thread
    
    task slave_thread();
        uart_transaction uart_tr;
        byte addr;
        
        vif.tx <= 1'bx;

        forever begin
            wait (vif.rst == 1'b0);

            wait (slave_queue.size() > 0);

            addr = slave_queue.pop_front().data;
            send_test_data(addr);
        end 
    endtask : slave_thread

    task drive_uart_frame(uart_transaction uart_tr);
        `uvm_info("DEBUG DRIVER", $sformatf("driver sent %s", uart_tr.conv2str()), UVM_HIGH)

        vif.tx <= uart_tr.start_bit;
        #full_bit;

        for (int i = 0; i < 8; i++) begin
            vif.tx <= uart_tr.data[i];
            #full_bit;
        end

        vif.tx <= uart_tr.parity_bit;
        #full_bit;

        vif.tx <= uart_tr.stop_bit;
        #full_bit;

        vif.tx <= 1'b1;
    endtask : drive_uart_frame

    //Imitate Mirror value from reg_model_slave
    task send_test_data(byte addr);
        uart_transaction test_tr;

        test_tr = uart_transaction::type_id::create("test_tr");

        test_tr.start_bit = 1'b0;
        test_tr.stop_bit = 1'b1;

        if (addr == 8'h00) begin
            test_tr.data = 8'hAA;
            test_tr.parity_bit = ^test_tr.data;
            drive_uart_frame(test_tr);
        end 
        else if (addr == 8'h01) begin
            test_tr.data = 8'hFF;
            test_tr.parity_bit = ^test_tr.data;
            drive_uart_frame(test_tr);
        end 
    endtask : send_test_data

endclass : uart_driver 

