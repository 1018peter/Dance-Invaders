# .mem to .coe
filename = "alien_rom.mem"
outfile = open("alien_rom.coe", "a+")
firstchar = True
with open(filename) as f:
    while True:
        if not firstchar:
            outfile.write(",\n")
            skipchar = f.read(1)
        c = f.read(1)
        firstchar = False
        if not c:
            break
        outfile.write(c)
    