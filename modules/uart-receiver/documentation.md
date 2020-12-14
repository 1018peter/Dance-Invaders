### Disclaimer
---
Taken from the example code in https://www.instructables.com/UART-Communication-on-Basys-3-FPGA-Dev-Board-Power-1/
All credits go to Digilent's alexwonglik.

### Instructions
---
In the constraints file, add:
```
##USB-RS232 Interface
set_property PACKAGE_PIN B18 [get_ports RxD]
set_property IOSTANDARD LVCMOS33 [get_ports RxD]
```
Packets can be read from the RxData bus, which is connected to the receiver's internal shift-buffer.
