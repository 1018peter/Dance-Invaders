
# 16-bit address
address = 0
for _size in range(0, 16):
    for _type in range(0, 2):
        for _frame in range(0, 2):
            for _deriv in range(0, 4):
                print(f"parameter [15:0] address_{_size}_{_type}_{_frame}_{_deriv} = {address};")
                address += (64 - 2*_size) * (32 - _size)

print("")
print("logic [15:0] pixel_addr;")
print("always @* begin")
print("case({{size_select, alien_type[1], frame_num[0], deriv_select}})")
for _size in range(0, 16):
    for _type in range(0, 2):
        for _frame in range(0, 2):
            for _deriv in range(0, 4):
                print(f"8'b{_size:>04b}{_type:>01b}{_frame:>01b}{_deriv:>02b}: pixel_addr = address_{_size}_{_type}_{_frame}_{_deriv} + read_addr;")
print("default : pixel_addr = 0;")
print("endcase")
print("end")
print("")
