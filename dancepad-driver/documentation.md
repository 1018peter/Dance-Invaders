### FPGA Dancepad Driver
---
#### Instructions: 
1. Find the COM port that is connected to the board (use Device Manager, right-click on Windows icon)
2. Plug in the Dancepad.
3. Type in the COM port's name (ie. COM4) You can input this field as a command-line argument, or you can input it after executing the file.
4. If all goes well, the Allegro display should pop up. Highlight the Allegro display and use keyboard inputs for debug.
5. Now, stepping on Dancepad buttons should send packets to the board.

#### Packet Encoding: (As detailed in the enum in the source code, all packets are 1-byte long)
- Button-Up pressed:     00000001
- Button-Down pressed:   00000010
- Button-Left pressed:   00000100
- Button-Right pressed:  00001000
- Button-Select pressed: 00010000
- Button-Start pressed:  00100000
- Button released (Idle): 00000000
