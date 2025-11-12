typedef enum bit {REG_WRITE = 1'b1, REG_READ = 1'b0} register_operation;
class register_transaction extends uvm_sequence_item;
    `uvm_object_utils(register_transaction);
    
    register_operation op;
    byte addr;
    byte data;
    
    function new(string name = "register_transaction");
        super.new(name);
    endfunction

    function string convert2str();
        return $sformatf("%s.0x%02h.0x%02h", op.name(), addr, data);
    endfunction : convert2str
endclass : register_transaction

