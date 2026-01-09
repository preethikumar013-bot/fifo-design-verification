## RTL Source Files

This directory contains the Register Transfer Level (RTL) implementation of a parameterized FIFO designed in SystemVerilog.

### Files
- fifo.sv  
  Combinational-read FIFO implementation with parameterized data width and depth.

- fifo_regread.sv  
  Registered-read FIFO variant introducing one-cycle read latency for timing-friendly designs.

### Features
- Parameterized DATA_WIDTH and DEPTH
- Full and empty flag generation
- Read and write pointer management
- Synchronous operation with active-low reset
