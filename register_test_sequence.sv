class register_test_sequence extends uvm_sequence #(register_transaction);
    `uvm_object_utils(register_test_sequence)

    function new(string name = "register_test_sequence");
        super.new(name);
    endfunction

    virtual task body();
        send_write(8'h01, 8'h11);
        send_write(8'h10, 8'h12);
        send_write(8'h11, 8'h13);

        send_read(8'h11);
        send_read(8'h12);
        send_read(8'h13);
    endtask : body

    task send_write(byte addr, byte data);
        register_transaction register_tr;
        register_tr = register_transaction::type_id::create("register_tr");
        register_tr.op = REG_WRITE;
        register_tr.addr = addr;
        register_tr.data = data;

        start_item(register_tr);
        finish_item(register_tr);
    endtask : send_write

    task send_read(byte addr);
        register_transaction register_tr;
        register_tr = register_transaction::type_id::create("register_tr");
        register_tr.op = REG_READ;
        register_tr.addr = addr;

        start_item(register_tr);
        finish_item(register_tr);
        `uvm_info("REG_SEQ", $sformatf("READ addr=0x%0h returned data=0x%0h", addr, register_tr.data), UVM_LOW)
    endtask : send_read
endclass : register_test_sequence

    