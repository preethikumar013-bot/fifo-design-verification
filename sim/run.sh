#!/bin/bash
set -e

echo "Running FIFO simulation..."

mkdir -p build

iverilog -g2012 -o build/fifo_sim \
  ../rtl/fifo.sv \
  ../rtl/fifo_regread.sv \
  ../tb/fifo_tb.sv

vvp build/fifo_sim

echo "Opening waveform..."
gtkwave fifo.vcd
