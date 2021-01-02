print("begin")
for _size in range(0, 16):
    for _type in range(0, 2):
        for _frame in range(0, 2):
            for _deriv in range(0, 4):
                print(f"reg size{_size}_type{_type}_frame{_frame}_deriv{_deriv} [0:{(64 - 2 * _size) * (32 - _size) - 1}];")
print("end")
print("")
print("initial begin")
for _size in range(0, 16):
    for _type in range(0, 2):
        for _frame in range(0, 2):
            for _deriv in range(0, 4):
                print(f"$readmemb(\"size{_size}_type{_type}_frame{_frame}_deriv{_deriv}.mem\", size{_size}_type{_type}_frame{_frame}_deriv{_deriv});")
print("end")
print("")
print("always @* begin")
print(f"case({{size_select, alien_type, frame_num, deriv_select}})")
for _size in range(0, 16):
    for _type in range(0, 2):
        for _frame in range(0, 2):
            for _deriv in range(0, 4):
                print(f"10'b{_size:>04b}{_type:>02b}{_frame:>02b}{_deriv:>02b}: palette_out = size{_size}_type{_type}_frame{_frame}_deriv{_deriv}[pixel_addr];")
print("default: palette_out = 0;")
print("endcase")
print("end")