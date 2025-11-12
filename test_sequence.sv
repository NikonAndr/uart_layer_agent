class test_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(test_sequence)

    function new(string name = "test_sequence");
        super.new(name);
    endfunction 

    virtual task body();
        send_write(8'h00, 8'hAF);
        send_read(8'h01);
    endtask : body

    task send_write(byte addr, byte data);
        uart_transaction uart_tr;
        uart_tr = uart_transaction::type_id::create("uart_tr");

        assert (uart_tr.randomize());
        uart_tr.data = 8'b0000_0001;
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);

        uart_tr = uart_transaction::type_id::create("uart_tr");
        assert (uart_tr.randomize());
        uart_tr.data = addr;
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);

        uart_tr = uart_transaction::type_id::create("uart_tr");
        assert (uart_tr.randomize());
        uart_tr.data = data;
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);
    endtask : send_write

    task send_read(byte addr);
        uart_transaction uart_tr;
        uart_tr = uart_transaction::type_id::create("uart_tr");

        assert (uart_tr.randomize());
        uart_tr.data = 8'b0000_0000;
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);

        uart_tr = uart_transaction::type_id::create("uart_tr");
        assert (uart_tr.randomize());
        uart_tr.data = addr;
        uart_tr.parity_bit = ^uart_tr.data;
        start_item(uart_tr);
        finish_item(uart_tr);
    endtask : send_read
endclass : test_sequence

        
    