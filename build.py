from pathlib import Path
import sys
import time

from common import (
    BUILD_OUTPUT_PATH,
    HDL_MODULES_MODULES_PATH,
    MODULES_PATH,
    TSFPGA_PATH,
    VUNIT_PATH,
)

sys.path.insert(0, str(TSFPGA_PATH))
sys.path.insert(0, str(VUNIT_PATH))

from tsfpga.examples.build_fpga_utils import arguments, setup_and_run
from tsfpga.build_project_list import BuildProjectList
from tsfpga.module import get_modules


def main() -> None:
    modules = get_modules(MODULES_PATH)
    modules += get_modules(HDL_MODULES_MODULES_PATH, names_avoid=set(["hard_fifo"]))

    for module in modules:
        if module.name == "spi_master":
            projects = module.get_yosys_projects()
            projects[0].build(BUILD_OUTPUT_PATH)


if __name__ == "__main__":
    start_time = time.time()
    main()
    print("--- %s seconds ---" % (time.time() - start_time))
