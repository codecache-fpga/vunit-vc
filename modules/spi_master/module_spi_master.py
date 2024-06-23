from tsfpga.module import BaseModule
from tsfpga.yosys.project import YosysNetlistBuild
from tsfpga.vivado.project import VivadoNetlistProject, VivadoProject


class Module(BaseModule):
    def get_build_projects(self) -> list[VivadoProject]:
        projects = []
        
        projects.append(
            VivadoNetlistProject(
                name="spi_master_synth_test",
                modules=[self],
                part="xc7z020clg400-1",
                top="spi_master"
            )
        )
        
        return projects
    
    def get_yosys_projects(self) -> YosysNetlistBuild:
        projects = []
        
        projects.append(
            YosysNetlistBuild(
                name="test",
                modules=[self],
                top="spi_master",
                synth_command="synth_xilinx -family xcup"
            )
        )
        
        return projects