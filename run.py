# --------------------------------------------------------------------------------------------------
# Copyright (c) Sebastian Hellgren. All rights reserved.
# --------------------------------------------------------------------------------------------------

import sys
from pathlib import Path

# Do PYTHONPATH insert() instead of append() to prefer any local repo checkout over any pip install
REPO_ROOT = Path(__file__).parent.resolve()
TSFPGA_PATH = REPO_ROOT / "tsfpga"
VUNIT_PATH = REPO_ROOT / "vunit"
sys.path.insert(0, str(TSFPGA_PATH))
sys.path.insert(0, str(VUNIT_PATH))

OUTPUT_PATH = REPO_ROOT / "out"

MODULES_PATHS = REPO_ROOT / "modules"

# First party libraries
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
    cli = get_arguments_cli(default_output_path=OUTPUT_PATH)
    args = cli.parse_args()

    modules = get_modules(MODULES_PATHS)

    simulation_project = SimulationProject(args=args)
    simulation_project.add_modules(args=args, modules=modules)

    simulation_project.vunit_proj.main()


if __name__ == "__main__":
    main()
