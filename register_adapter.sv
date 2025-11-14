class register_adapter extends uvm_reg_adapter;
    `uvm_object_utils(register_adapter)

    function new(string name = "register_adapter");
        super.new(name);
        supports_byte_enable = 0;
        provides_responses = 1;
    endfunction 

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        register_transaction register_tr;
        register_tr = register_transaction::type_id::create("register_tr");
        register_tr.op = (rw.kind == UVM_WRITE) ? REG_WRITE : REG_READ;
        register_tr.addr = rw.addr[7:0];
        if (rw.kind == UVM_WRITE) begin
            register_tr.data = rw.data[7:0];
        end

        `uvm_info("REG2BUS", "reg2bus triggered", UVM_HIGH)
        return register_tr;
    endfunction : reg2bus

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        register_transaction register_tr;
        if (!$cast(register_tr, bus_item)) begin
            `uvm_fatal("ADAPTER", "cast failed")
        end
        rw.kind = (register_tr.op == REG_WRITE) ? UVM_WRITE : UVM_READ;
        rw.addr = register_tr.addr;
        rw.data = register_tr.data;
        rw.status = UVM_IS_OK;
        `uvm_info("BUS2REG", "bus2reg triggered", UVM_HIGH)
    endfunction : bus2reg
endclass : register_adapter 