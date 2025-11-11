class uart_monitor extends uvm_monitor;
    `uvm_component_utils(uart_monitor)

    virtual uart_if.monitor vif;
    uart_agent_config cfg;

    time half_bit;

    uvm_analysis_port #(uart_transaction) uart_slave_ap;
    uvm_analysis_port #(uart_transaction) uart_master_ap;

    function new(string name = "uart_monitor", uvm_component parent);
        super.new(name, parent);
        uart_slave_ap = new("uart_slave_ap", this);
        uart_master_ap = new("uart_master_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.monitor)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "uart_monitor couldn't retrieve vif from cfg_db")
        end

        if (!uvm_config_db#(uart_agent_config)::get(this, "", "agent_config", cfg) || cfg == null) begin
            `uvm_fatal("NO_CFG", "uart_monitor couldn't retrieve cfg from cfg_db")
        end

        half_bit = (cfg.var_ps * 1ps) / 2;
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);

        forever begin
            fork 
            begin : monitor
                forever begin
                    uart_transaction uart_tr;
                    capture_uart_frame(uart_tr);
                    if (cfg.is_master) 
                        uart_master_ap.write(uart_tr);
                    else 
                        uart_slave_ap.write(uart_tr);
                end

            end 
            begin : reset
                reset_thread();
            end
            join_any
            disable fork;

            @(negedge vif.rst);
        end 
    endtask : run_phase

    task reset_thread();
        @(posedge vif.rst);
    endtask : reset_thread

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

        `uvm_info("DEBUG MONITOR", $sformatf("[%s] monitor captured %s", get_parent().get_name(), uart_tr.convert2str()), UVM_HIGH)
    endtask : capture_uart_frame
endclass : uart_monitor




