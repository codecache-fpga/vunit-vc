An example repository on how to create [VUnit](https://github.com/VUnit/) Verification Components.

The [TSFPGA framework](https://tsfpga.com/) is used handle the source code in the form of [modules](https://tsfpga.com/module_structure.html).

**Requirements**
1. Python >= 3.7
2. A simulator on PATH, e.g [GHDL](https://github.com/ghdl/ghdl) or [NVC](https://github.com/nickg/nvc). Commercial alternatives such as ModelSim are also supported.

**Getting started**
1. Clone the repository
2. Update the submodules (VUnit and TSFPGA)
```
git submodule update --init --recursive
```

**Running the tests**
```
python run.py
```
