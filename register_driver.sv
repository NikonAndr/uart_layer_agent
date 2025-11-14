class register_driver extends uvm_driver #(register_transaction);
    `uvm_component_utils(register_driver)

    uvm_analysis_imp#(uart_transaction, register_driver) uart_master_imp;

    virtual uart_if.reset_only vif;
    register_agent_config cfg;

    uart_sequencer uart_master_sequencer;

    uart_transaction read_response_queue[$];
    event response_recieved;
    bit item_active;

    function new(string name = "register_driver", uvm_component parent);
        super.new(name, parent);
        uart_master_imp = new("uart_master_imp", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual uart_if.reset_only)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "register_driver couldn't retrieve reset vif")
        end
    endfunction : build_phase

    virtual function void write(uart_transaction uart_tr);
        read_response_queue.push_back(uart_tr);
        ->response_recieved;
    endfunction : write
    
    virtual task run_phase(uvm_phase phase);
        register_transaction register_tr;
        super.run_phase(phase);

        item_active = 1'b0;

        forever begin
            fork 
            begin : drive
                forever begin
                    seq_item_port.get_next_item(register_tr);
                    item_active = 1'b1;
                    if (register_tr.op == REG_WRITE) 
                        send_write(register_tr);
                    else 
                        send_read(register_tr);
                    
                    seq_item_port.item_done(register_tr);
                    item_active = 1'b0;
                end
            end 

            begin : reset
                @(posedge vif.rst);
            end
            join_any
            disable fork;
            
            //clear sequencer_queue 
            if (item_active) begin
                seq_item_port.item_done(register_tr);
                item_active = 1'b0;
            end 

            read_response_queue.delete();
            @(negedge vif.rst);
        end 
    endtask : run_phase

    task send_uart_byte(byte data);
        uart_byte_sequence seq;

        seq = uart_byte_sequence::type_id::create("seq");
        seq.byte_data = data;
        seq.start(uart_master_sequencer);
    endtask : send_uart_byte

    task send_write(register_transaction register_tr);
        send_uart_byte(8'b0000_0001);
        send_uart_byte(register_tr.addr);
        send_uart_byte(register_tr.data);
    endtask : send_write

    task send_read(register_transaction register_tr);
        uart_transaction response;

        send_uart_byte(8'b0000_0000);
        send_uart_byte(register_tr.addr);

        fork
            begin
                @(response_recieved);
                response = read_response_queue.pop_front();
                register_tr.data = response.data;
            end
            begin 
                @(posedge vif.rst);
            end
        join_any 
        disable fork;

    endtask : send_read
endclass : register_driver