from pathlib import Path

import vunit_util

# NOTE: you can add the example module in the rtl/src folder here to
# compile that module and include it in a test. This simple example only pulls in the tb source code.
WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".." / "rtl"
SUBMODULES = Path(__file__).parent / ".." / "submodules"
SRC = RTL_ROOT / "src"
AXIS = SRC / "axis"
AXI_LITE = SRC / "axi_lite"
ETHERNET = SRC / "ethernet"
UDP = SRC / "udp"
EXAMPLES = SRC / "examples"

AXIS_LIB = SUBMODULES / "verilog-axis"
ETHERNET_LIB = SUBMODULES / "verilog-ethernet"

TESTBENCHES = Path(__file__).parent / ".." / "rtl" / "testbenches"
# Create source list
sources = [
    AXIS / "*.sv",
    AXI_LITE / "*.sv",
    ETHERNET / "mdio" / "*.sv",
    TESTBENCHES / "mdio_writer_tb.sv",
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("mdio_writer_tb")

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()
