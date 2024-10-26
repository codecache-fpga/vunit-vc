from pathlib import Path
from tsfpga.module import BaseModule
from tsfpga.module import get_modules
from tsfpga.yosys.project import YosysNetlistBuild
from tsfpga.vivado.project import VivadoNetlistProject, VivadoProject


class Module(BaseModule):
    def setup_vunit(self, vunit_proj, **kwargs):
        tb = vunit_proj.library(self.library_name).test_bench("tb_spi_master")
        for use_data_fifo in [False, True]:
            if use_data_fifo:
                for data_fifo_depth in [32, 1024]:
                    tb.add_config(
                        name=f"use_data_fifo={use_data_fifo}.data_fifo_depth={data_fifo_depth}",
                        generics=dict(use_data_fifo=use_data_fifo),
                    )
            else:
                tb.add_config(
                    name=f"use_data_fifo={use_data_fifo}",
                    generics=dict(use_data_fifo=use_data_fifo),
                )

    def get_build_projects(self) -> list[VivadoProject]:
        projects = []

        projects.append(
            VivadoNetlistProject(
                name="spi_master_synth_test",
                modules=[self],
                part="xc7z020clg400-1",
                top="spi_master",
            )
        )

        return projects

    def get_yosys_projects(self) -> YosysNetlistBuild:
        projects = []

        modules = get_modules(Path("hdl-modules") / "modules")
        modules.append(self)

        projects.append(
            YosysNetlistBuild(
                name="test",
                modules=modules,
                top="spi_master",
                synth_command="synth_xilinx -family xcup",
            )
        )

        return projects
