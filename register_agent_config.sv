class register_agent_config extends uvm_object;
    `uvm_object_utils(register_agent_config)

    bit is_master;

    function new(string name = "register_agent_config");
        super.new(name);
    endfunction
endclass : register_agent_config