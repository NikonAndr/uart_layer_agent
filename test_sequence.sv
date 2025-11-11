class test_sequence_A1 extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(test_sequence_A1)

    function new(string name = "test_sequence_A1");
        super.new(name);
    endfunction 

    virtual task body();
        `uvm_info(get_type_name(), "=== A1 SEQUENCE STARTED ===", UVM_LOW)

        repeat (10) begin
            send_random_data();
        end
        `uvm_info(get_type_name(), "=== A1 SEQUENCE COMPLETE ===", UVM_LOW)
    endtask : body

    task send_random_data();
        uart_transaction uart_tr;
        uart_tr = uart_transaction::type_id::create("uart_tr");

        assert(uart_tr.randomize());

        start_item(uart_tr);
        finish_item(uart_tr);
    endtask
endclass : test_sequence_A1

class test_sequence_A2 extends uvm_sequence #(uart_transaction);
    `uvm_object_utils(test_sequence_A2)

    function new(string name = "test_sequence_A2");
        super.new(name);
    endfunction 

    virtual task body();
        `uvm_info(get_type_name(), "=== A2 SEQUENCE STARTED ===", UVM_LOW)

        repeat (3) begin
            send_random_data();
        end
        `uvm_info(get_type_name(), "=== A2 SEQUENCE COMPLETED ===", UVM_LOW)

    endtask : body

    task send_random_data();
        uart_transaction uart_tr;
        uart_tr = uart_transaction::type_id::create("uart_tr");

        assert(uart_tr.randomize());

        start_item(uart_tr);
        finish_item(uart_tr);
    endtask
endclass : test_sequence_A2


