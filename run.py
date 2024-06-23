# --------------------------------------------------------------------------------------------------
# Copyright (c) Sebastian Hellgren. All rights reserved.
# --------------------------------------------------------------------------------------------------

import sys

from common import MODULES_PATH, SIM_OUTPUT_PATH, TSFPGA_PATH, VUNIT_PATH

sys.path.insert(0, str(TSFPGA_PATH))
sys.path.insert(0, str(VUNIT_PATH))

from tsfpga.examples.simulation_utils import (
    SimulationProject,
    get_arguments_cli,
)
from tsfpga.module import get_modules

def main():
    """
    Main function for the simulation flow. If you are setting up a new simulation environment
    you probably want to copy and modify this function. The other functions and classes
    should be reusable in most cases.
    """
    cli = get_arguments_cli(default_output_path=SIM_OUTPUT_PATH)
    args = cli.parse_args()

    modules = get_modules(MODULES_PATH)

    simulation_project = SimulationProject(args=args)
    simulation_project.add_modules(args=args, modules=modules)

    simulation_project.vunit_proj.main()


if __name__ == "__main__":
    main()
