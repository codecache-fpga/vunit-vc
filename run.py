# --------------------------------------------------------------------------------------------------
# Copyright (c) Sebastian Hellgren. All rights reserved.
# --------------------------------------------------------------------------------------------------

import sys

from common import (
    MODULES_PATH,
    REPO_ROOT,
    SIM_OUTPUT_PATH,
    TEMP_OUTPUT_PATH,
    TSFPGA_PATH,
    VUNIT_PATH,
)

sys.path.insert(0, str(TSFPGA_PATH))
sys.path.insert(0, str(VUNIT_PATH))

from tsfpga.examples.simulation_utils import (
    SimulationProject,
    create_vhdl_ls_configuration,
    get_arguments_cli,
)
from tsfpga.module import get_modules


def main():
    cli = get_arguments_cli(default_output_path=SIM_OUTPUT_PATH)
    args = cli.parse_args()

    modules = get_modules(MODULES_PATH)

    # Run this every time to run as often as possible to keep vhdl_ls.toml updated
    create_vhdl_ls_configuration(REPO_ROOT, TEMP_OUTPUT_PATH, modules=modules)

    simulation_project = SimulationProject(args=args)
    simulation_project.add_modules(args=args, modules=modules)

    if not args.vivado_skip and simulation_project.vunit_proj.get_simulator_name() != "nvc":
        simulation_project.add_vivado_simlib()

    simulation_project.vunit_proj.main()


if __name__ == "__main__":
    main()
