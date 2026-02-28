import re

def dis_to_bin(dis_file):
    addr_f = open("instr_addr.bin", "w")
    data_f = open("instr_data.bin", "w")
    
    with open(dis_file, 'r') as f:
        for line in f:
            # Match lines like: "   1030c:	0105a683          	lw	a3,16(a1)"
            match = re.search(r"([0-9a-f]+):\s+([0-9a-f]{8})", line)
            if match:
                addr_hex = match.group(1)
                data_hex = match.group(2)
                
                # Convert to 32-bit binary strings
                addr_bin = format(int(addr_hex, 16), '032b')
                data_bin = format(int(data_hex, 16), '032b')
                
                addr_f.write(addr_bin + "\n")
                data_f.write(data_bin + "\n")
                
    addr_f.close()
    data_f.close()

dis_to_bin("inst.txt")