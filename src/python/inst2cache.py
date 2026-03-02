
int_list=[]
file_path = 'lw_addr.bin'
with open(file_path, 'r') as file:
    lines_list = file.readlines()
    for l in lines_list:
        int_list.append(int(l, 2))
file_path = 'sw_addr.bin'
with open(file_path, 'r') as file:
    lines_list = file.readlines()
    for l in lines_list:
        int_list.append(int(l, 2))
print("data_addr_min:",min(int_list))
print("data_addr_max:",max(int_list))

file_path = 'instr_addr.bin'
int_list=[]
with open(file_path, 'r') as file:
    lines_list = file.readlines()
    for l in lines_list:
        int_list.append(int(l, 2))
print("inst_addr_min:",min(int_list))
print("inst_addr_max:",max(int_list))

mem_list=['00000000000000000000000000000000\n']*32*4
file_path = 'instr_data.bin'
with open(file_path, 'r') as file:
    lines_list = file.readlines()
    print(len(lines_list))
    for i in range(len(lines_list)):
        idx=int_list[i]//4-16496
        mem_list[idx]=lines_list[i]
file_path = 'instr_final.bin'
with open(file_path, "w") as f:
    f.writelines(mem_list)