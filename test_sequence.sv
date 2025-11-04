class test_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(test_sequence)

    function new(string name = "test_sequence");
        super.new(name);
    endfunction 

    virtual task body();
        send_read(8'h00);

        send_read(8'h01);

        send_write(8'h00, 8'h12);
    endtask : body

    task send_write(byte addr, byte data);
        uart_transaction uart_tr;
        
        // CMD
        uart_tr = uart_transaction::type_id::create("uart_tr");
        uart_tr.randomize();
        uart_tr.ft = FRAME_CMD;
        
        //WRITE
        uart_tr.data = 8'h01;  
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);
        
        // ADDR
        uart_tr = uart_transaction::type_id::create("uart_tr");
        uart_tr.randomize();
        uart_tr.ft = FRAME_ADDR;
        uart_tr.data = addr;
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);
        
        // DATA
        uart_tr = uart_transaction::type_id::create("uart_tr");
        uart_tr.randomize();
        uart_tr.ft = FRAME_DATA;
        uart_tr.data = data;
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);
    endtask

    task send_read(byte addr);
        uart_transaction uart_tr;
        
        // CMD
        uart_tr = uart_transaction::type_id::create("uart_tr");
        uart_tr.randomize();
        uart_tr.ft = FRAME_CMD;
        uart_tr.data = 8'h00; // READ
        uart_tr.parity_bit = ^uart_tr.data;  
        start_item(uart_tr);
        finish_item(uart_tr);
        
        // ADDR
        uart_tr = uart_transaction::type_id::create("uart_tr");
        uart_tr.randomize();
        uart_tr.ft = FRAME_ADDR;
        uart_tr.data = addr;
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);
    endtask
endclass : test_sequence 


