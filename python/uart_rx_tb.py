"""
Example VUnit testbench Python script for running RTL module testbench in SystemVerilog
"""

from pathlib import Path

import vunit_util

# NOTE: you can add the example module in the rtl/src folder here to
# compile that module and include it in a test. This simple example only pulls in the tb source code.
WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".." / "rtl"
SRC = Path(__file__).parent / ".." / "rtl" / "src"
AXIS = Path(__file__).parent / ".." / "rtl" / "src" / "axis"
UART = Path(__file__).parent / ".." / "rtl" / "src" / "uart"
METASTABILITY = Path(__file__).parent / ".." / "rtl" / "src" / "metastability-tools"

TESTBENCHES = Path(__file__).parent / ".." / "rtl" / "testbenches"
# Create source list
sources = [
    TESTBENCHES / "uart_rx_tb.sv",
    AXIS / "*.sv",
    UART / "*.sv",
    METASTABILITY / "*.sv",
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("uart_rx_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()
