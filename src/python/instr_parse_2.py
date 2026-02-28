file_path = 'instr_addr.bin'

int_list=[]
# Using a 'with' statement is the recommended way for file handling
with open(file_path, 'r') as file:
    lines_list = file.readlines()
    print(len(lines_list))
    for l in lines_list:
        int_list.append(int(l, 2))
#file_path = 'sw_addr.bin'
#with open(file_path, 'r') as file:
#    lines_list = file.readlines()
#    print(len(lines_list))
#    for l in lines_list:
#        int_list.append(int(l, 2))
print(max(int_list))
print(min(int_list))
mem_list=['00000000000000000000000000000000\n']*102*4
file_path = 'instr_data.bin'
with open(file_path, 'r') as file:
    lines_list = file.readlines()
    print(len(lines_list))
    for i in range(len(lines_list)):
        idx=int_list[i]//4-4107*4
        mem_list[idx]=lines_list[i]
file_path = 'instr_final.bin'
with open(file_path, "w") as f:
    f.writelines(mem_list)