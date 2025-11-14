class uart_driver extends uvm_driver#(uart_transaction);
    `uvm_component_utils(uart_driver)

    virtual uart_if.driver vif;
    uart_agent_config cfg;

    time full_bit;
    bit item_active;

    function new(string name = "uart_driver", uvm_component parent);
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.driver)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "uart_driver couldn't retrieve vif from cfg_db")
        end

        if (!uvm_config_db#(uart_agent_config)::get(this, "", "agent_config", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_driver couldn't retrieve cfg from cfg_db")
        end

        full_bit = cfg.var_ps * 1ps;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        item_active = 1'b0;

        forever begin
            fork 
            begin : drive
                forever begin
                    uart_transaction uart_tr;
                    seq_item_port.get_next_item(uart_tr);
                    item_active = 1'b1;
                    drive_uart_frame(uart_tr);
                    seq_item_port.item_done();
                    item_active = 1'b0;
                end
            end 

            begin : reset
                reset_thread();
            end
            join_any
            disable fork;
            
            
            //clear sequencer_queue 
            if (item_active) begin
                seq_item_port.item_done();
                item_active = 1'b0;
            end 

            @(negedge vif.rst);
            vif.tx <= 1'b1;
        end 
    endtask : run_phase

    task reset_thread();
        @(posedge vif.rst);
        vif.tx <= 1'b1;
    endtask : reset_thread

    task drive_uart_frame(uart_transaction uart_tr);
        `uvm_info("UART_DRIVER", $sformatf("[%s] driver sent %s", get_parent().get_name(), uart_tr.convert2str()), UVM_HIGH)

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
endclass : uart_driver 
