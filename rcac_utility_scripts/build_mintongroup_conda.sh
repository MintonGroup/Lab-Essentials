#!/bin/zsh -l
# ************************************************
# Builds the conda environment for the mintongroup
# ************************************************

set -a
SCRIPT_DIR=$(realpath $(dirname $0))


# Check that we are not on a front end node
if { hostname | grep -E 'fe|login'; } >/dev/null 2>&1; then
    echo "You are on a front end node. Please run this script on a compute node."
    exit 1
fi

OMP_NUM_THREADS=$(squeue -u $(whoami) | grep $SLURM_JOB_ID | awk -F' ' '{print $6}')

# Determine if we are on Bell or Negishi
MACHINE_NAME=$(uname -n | awk -F. '{ 
    if ($2 == "negishi" || $2 == "bell") 
        print $2; 
    else {
        split($1, a, "-"); 
        if (length(a) > 1) 
            print a[1]; 
        else 
            print "Unknown"; 
    }
}')

if [[ $MACHINE_NAME == "Unknown" ]]; then
    echo "Unknown machine. Exiting.\n"
    exit 1
fi

module purge
module load anaconda/2024.02-py311
module load use.own

if { conda env list | grep 'mintongroup'; } >/dev/null 2>&1; then
    echo "The mintongroup environment already exists. Do you want to remove it? (y/n)"
    read answer
    if [[ $answer == "y" ]]; then
        conda env remove -n mintongroup
        env_dir=$(conda env list | grep 'mintongroup' | awk '{print $1}')
        mod_dir=${HOME}/privatemodules/conda-env/$(ls -l ${HOME}/privatemodules/conda-env | grep mintongroup | awk '{print $9}') 

        # Check if the output is non-empty and the directory exists
        if [[ -n "$env_dir" && -d "$env_dir" ]]; then
            echo "Removing directory: $env_dir"
            rm -rf "$env_dir"
            echo "Directory removed successfully."
        else
            echo "mintongroup conda environment directory does not exist."
        fi
        if [[ -n "$mod_dir" && -d "$mod_dir" ]]; then
            echo "Removing directory: $mod_dir"
            rm -rf "$mod_dir"
            echo "Directory removed successfully."
        else
            echo "mintongroup module file does not exist."
        fi

    else
        echo "Do you want to update the mintongroup environment? (y/n) "
        read answer
        if [[ $answer == "y" ]]; then
            conda env update -f ${SCRIPT_DIR}/mintongroup_conda_env.yml
            exit 0
        else
            echo "Exiting without updating the mintongroup environment."
            exit 0
        fi
    fi
fi
echo "Creating the mintongroup environment. This may take a few minutes."
conda env create -f ${SCRIPT_DIR}/mintongroup_conda_env.yml
conda-env-mod module -n mintongroup --jupyter
# The following is needed to prevent some system libraries from being replaced by incompatible conda ones and to 
# prevent the python version in the PYTHONPATH from being an obsolete one (pytest won't work without this)
if [[ $MACHINE_NAME == "bell" ]]; then
    echo 'prepend_path("LD_LIBRARY_PATH","/lib64")' >> ${HOME}/privatemodules/conda-env/mintongroup-py3.11.7.lua
    echo 'remove_path("PYTHONPATH","/apps/cent7/xalt/site")' >> ${HOME}/privatemodules/conda-env/mintongroup-py3.11.7.lua
    echo 'remove_path("PYTHONPATH","/apps/cent7/xalt/libexec")' >> ${HOME}/privatemodules/conda-env/mintongroup-py3.11.7.lua
fi
