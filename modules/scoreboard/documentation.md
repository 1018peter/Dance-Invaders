The scoreboard is built as an optimal sorting network for 6 key-value pairs.

The first two ports of the scoreboard are clk and rst, which are self-explanatory.

Then comes the port insert, which should be asserted for one clock pulse for every insertion.

After insert, comes the bus containing the key to be inserted and the bus containing the value to be inserted, which, in this case, should be the new score and name.

Finally comes five key-value bus pairs in order of greatest to smallest.
