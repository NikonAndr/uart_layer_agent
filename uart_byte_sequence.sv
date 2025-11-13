class uart_byte_sequence extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(uart_byte_sequence)

    byte byte_data;

    function new(string name = "uart_byte_sequence");
        super.new(name);
    endfunction

    virtual task body();
        uart_transaction uart_tr;

        uart_tr = uart_transaction::type_id::create("uart_tr");
        assert(uart_tr.randomize());
        uart_tr.data = byte_data;
        uart_tr.parity_bit = ^uart_tr.data;

        start_item(uart_tr);
        finish_item(uart_tr);
    endtask : body 
endclass : uart_byte_sequence

