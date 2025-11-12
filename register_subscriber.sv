class register_subscriber extends uvm_subscriber#(register_transaction);
    `uvm_component_utils(register_subscriber)

    function new(string name = "register_subscriber", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void write(register_transaction t);
        `uvm_info("REG_SUB", t.convert2str(), UVM_MEDIUM)
    endfunction : write
endclass : register_subscriber