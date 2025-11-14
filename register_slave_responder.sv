class register_slave_responder extends uvm_component;
    `uvm_component_utils(register_slave_responder)

    virtual uart_if.reset_only vif;

    register_block reg_model_slave;
    
    uart_sequencer uart_slave_sequencer;
    event read_event;

    byte read_addr_queue[$];
    byte read_addr;
    byte read_data;

    uvm_analysis_imp#(register_transaction, register_slave_responder) reg_monitor_imp;

    function new(string name = "register_slave_responder", uvm_component parent);
        super.new(name, parent);
        reg_monitor_imp = new("reg_monitor_imp", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.reset_only)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "reg_slave_responder couldn't get vif")
        end

        if(!uvm_config_db#(register_block)::get(this, "", "reg_model", reg_model_slave) || reg_model_slave == null) begin
            `uvm_fatal("NO_REG_MODEL", "slave_responder couldn't get reg_model_slave from cfg db")
        end
    endfunction : build_phase

    virtual function void write(register_transaction register_tr);
        if (register_tr.op == REG_READ) begin
            read_addr_queue.push_back(register_tr.addr);
            ->read_event;
        end
    endfunction : write

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin 
            fork
                begin : send_sequence
                    forever begin 
                        @(read_event);
                        if (read_addr_queue.size() > 0) begin
                            read_addr = read_addr_queue.pop_front();
                            case (read_addr)
                                8'h00 : read_data = reg_model_slave.R1.get_mirrored_value();
                                8'h01 : read_data = reg_model_slave.R2.get_mirrored_value();
                                default : begin
                                    `uvm_warning("SLAVE_RESPONDER", "unknown addr, sending 0x00")
                                    read_data = 8'h00;
                                end
                            endcase
                            send_uart_byte(read_data);
                        end 
                        else begin
                            `uvm_fatal("SLAVE_RESPONDER", "size of read_addr_queue == 0")
                        end
                    end
                end
                @(posedge vif.rst);
            join_any
            disable fork;

            @(negedge vif.rst);
            read_addr_queue.delete();
        end
    endtask : run_phase

    task send_uart_byte(byte data);
        uart_byte_sequence seq;

        seq = uart_byte_sequence::type_id::create("seq");
        seq.byte_data = data;
        seq.start(uart_slave_sequencer);
    endtask : send_uart_byte
endclass : register_slave_responder

