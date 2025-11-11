class uart_transaction extends uvm_sequence_item;
    rand bit start_bit;
    rand byte data;
    rand bit parity_bit;
    rand bit stop_bit;

    constraint valid_bits {
        start_bit == 1'b0;
        parity_bit == ^data;
        stop_bit == 1'b1;
    };

    `uvm_object_utils(uart_transaction)

    function new(string name = "uart_transaction");
        super.new(name);
    endfunction 

    function string convert2str();
        return $sformatf("%0b %8b %0b %0b", start_bit, data, parity_bit, stop_bit);
    endfunction : convert2str 
endclass : uart_transaction





    