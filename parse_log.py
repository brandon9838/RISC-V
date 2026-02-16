import re

def to_bin32(value_hex):
    # Converts hex string (0x...) to 32-bit binary string
    val = int(value_hex, 16)
    return format(val & 0xFFFFFFFF, '032b')

def to_bin5(reg_name):
    # Converts 'x7' or 'x1' to 5-bit binary string
    reg_num = int(re.search(r'x(\d+)', reg_name).group(1))
    return format(reg_num, '05b')

def generate_tb_files(input_file):
    # File handles for the 6 outputs
    files = {
        "reg_addr": open("reg_addr.bin", "w"), "reg_data": open("reg_data.bin", "w"),
        "sw_addr": open("sw_addr.bin", "w"),   "sw_data": open("sw_data.bin", "w"),
        "lw_addr": open("lw_addr.bin", "w"),   "lw_data": open("lw_data.bin", "w")
    }

    with open(input_file, 'r') as f:
        lines = f.readlines()

    for i in range(len(lines)):
        # Check if current line is an instruction line
        instr_line = lines[i]
        if "core   0: 0x" in instr_line and "(" in instr_line:
            # Look at the VERY NEXT line for the commit data
            if i + 1 < len(lines):
                commit = lines[i+1]
                
                # 1 & 2: Register Writes (e.g., x7 0x00013b78)
                reg_match = re.search(r"x(\d+)\s+(0x[0-9a-f]+)", commit)
                if reg_match and "mem" not in commit:
                    files["reg_addr"].write(to_bin5(reg_match.group(0)) + "\n")
                    files["reg_data"].write(to_bin32(reg_match.group(2)) + "\n")

                # 3 & 4: Store Operations (e.g., mem 0x13c34 0x0)
                # Spike log for stores: mem [addr] [value]
                sw_match = re.search(r"mem\s+(0x[0-9a-f]+)\s+(0x[0-9a-f]+)", commit)
                if sw_match and "sw" in instr_line:
                    files["sw_addr"].write(to_bin32(sw_match.group(1)) + "\n")
                    files["sw_data"].write(to_bin32(sw_match.group(2)) + "\n")

                # 5 & 6: Load Operations (e.g., x10 0x1234 mem 0x13c34)
                # Spike log for loads: [dest_reg] [val] mem [addr]
                lw_match = re.search(r"x\d+\s+(0x[0-9a-f]+)\s+mem\s+(0x[0-9a-f]+)", commit)
                if lw_match and "lw" in instr_line:
                    files["lw_addr"].write(to_bin32(lw_match.group(2)) + "\n")
                    files["lw_data"].write(to_bin32(lw_match.group(1)) + "\n")

    for f in files.values(): f.close()

generate_tb_files("clean_log.txt")