from pathlib import Path

import vunit_util

# NOTE: you can add the example module in the rtl/src folder here to
# compile that module and include it in a test. This simple example only pulls in the tb source code.
WORKSPACE = Path(__file__).parent / "workspace"
RTL_ROOT = Path(__file__).parent / ".." / "rtl"
SUBMODULES = Path(__file__).parent / ".." / "submodules"
SRC = RTL_ROOT / "src"
AXIS = SRC / "axis"
SPI = SRC / "spi"
METASTABILITY = SRC / "metastability-tools"

TESTBENCHES = Path(__file__).parent / ".." / "rtl" / "testbenches"
# Create source list
sources = [
    TESTBENCHES / "spi_master_tb.sv",
    AXIS / "*.sv",
    SPI / "*.sv",
    METASTABILITY / "*.sv",
]

# Create VUnit instance and add sources to library
vu, lib = vunit_util.init(WORKSPACE)
lib.add_source_files(sources)

# Create testbench
tb = lib.test_bench("spi_master_tb")

# add all posible idle and clock polarity variants
SPI_MODES = {
    # [CPOL, CPHA]
    "MODE0" : [0, 0],
    "MODE1" : [0, 1],
    "MODE2" : [1, 0],
    "MODE3" : [1, 1],
}

for mode, params in SPI_MODES.items():
    tb.add_config(
        "SPI_%s" % (mode),
        parameters={
            "CPOL" : params[0],
            "CPHA" : params[1]
        }
    )

# Suppress vopt deprecation error
vu.add_compile_option('modelsim.vlog_flags', ['-suppress', '12110'])

# Run
vu.main()
