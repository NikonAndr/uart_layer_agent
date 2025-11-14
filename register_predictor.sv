class register_predictor extends uvm_reg_predictor#(register_transaction);
    `uvm_component_utils(register_predictor)

    function new(string name = "register_predictor", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void write(register_transaction tr);
        if (tr.op == REG_WRITE) begin
            super.write(tr);
        end
    endfunction : write
endclass : register_predictor
