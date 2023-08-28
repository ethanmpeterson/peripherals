"""
AXIS Async FIFO Wrapper Python TB
"""

from pathlib import Path

import vunit_util

WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".." / "rtl"
SRC = Path(__file__).parent / ".." / "rtl" / "src"
AXIS = Path(__file__).parent / ".." / "rtl" / "src" / "axis"
UART = Path(__file__).parent / ".." / "rtl" / "src" / "uart"
METASTABILITY = Path(__file__).parent / ".." / "rtl" / "src" / "metastability-tools"
SUBMODULES = Path(__file__).parent / ".." / "submodules"

TESTBENCHES = Path(__file__).parent / ".." / "rtl" / "testbenches"
# Create source list
sources = [
    SUBMODULES / "verilog-axis" / "rtl" / "axis_async_fifo.v",
    TESTBENCHES / "axis_async_fifo_wrapper_tb.sv",
    AXIS / "*.sv",
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("axis_async_fifo_wrapper_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()
