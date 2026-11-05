read_verilog rtl/alu.v
read_verilog rtl/alu_control.v
read_verilog rtl/branch_unit.v
read_verilog rtl/control_unit.v
read_verilog rtl/ex_mem_reg.v
read_verilog rtl/forwarding_unit.v
read_verilog rtl/hazard_unit.v
read_verilog rtl/id_ex_reg.v
read_verilog rtl/if_id_reg.v
read_verilog rtl/imm_gen.v
read_verilog rtl/mem_wb_reg.v
read_verilog rtl/pc.v
read_verilog rtl/regfile.v
read_verilog rtl/rv32i_core.v

hierarchy -top rv32i_core

proc
opt
fsm
opt
memory
opt
techmap
opt
abc
clean

stat

write_verilog results/rv32i_core_synth.v
