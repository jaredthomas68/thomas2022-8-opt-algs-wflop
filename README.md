[![DOI](https://zenodo.org/badge/543173996.svg)](https://zenodo.org/badge/latestdoi/543173996)

# A Comparison of Eight Optimization Methods Applied to a Wind Farm Layout Optimization Problem
By Jared J. Thomas, Nicholas F. Baker, Paul Malisani, Erik Quaeghebeur, Sebastian Sanchez Perez-Moreno, John Jasa, Christopher Bay, Federico Tilli, David Bieniek, Nick Robinson, Andrew P. J. Stanley, Wesley Holt, and Andrew Ning.

A manuscript submitted to Wind Energy Science.

This repository is for shared code, data, and other things, but not the manuscript (which is handled on overleaf).

- Optimization results can be found in the `.yaml` files in `./results/optimization-results/`
- Conda environment used for this project can be found in `conda-env.yml`
    - create with `$ conda env create -f conda-env.yml`
    - activate with `$ conda activate julia-env`
    - this environment includes julia, so you don't need to install it directly. 
- Image/table data and generation code can be found at `./image-gen/`
    - The figure/table generation script for most of the figures and one table is in Julia. 
        - Start a Julia session: `$ julia`
        - Activate the environment at the same location from within Julia using `] activate .`
        - Include the script: `include("image-gen.jl")`
        - Generate the images: `make_images()`
    - The DEBO figure code is located in `image-gen/DataPlotDEBO/`
        - From the terminal, run `$ python FiguresPaper.py`
- Physics models for the optimization in both Python and Julia can be called from `./src/physics-models/`
    - Julia
        - Start a Julia session using `$ julia`
        - Activate the environment at the same location from within Julia using `] activate .`
            - You may need to go into the dev'd FLOWFarm repository and check out commit `ec5270203786d5bcf065fff8c80bd7710906a40e`
        - Run `include("provided_model.jl")`
    - Python
        - Run `$ python provided_model.py`
