#!/bin/bash
# ********************************************************************************************************************************
# Transfers all of the simulation data to Data Depot 
#
# Author: David A. Minton
# ********************************************************************************************************************************
#SBATCH -A daminton
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=12-00:00:00
#SBATCH --cpus-per-task=1
#SBATCH --job-name=autotransfer
#SBATCH -o %x_%a.out
#SBATCH -e %x_%a.err
#SBATCH --mail-user=daminton@purdue.edu
#SBATCH --mail-type=ALL

dest="/depot/daminton/data"
PROJECT_NAME="lew3_clonesim103_GR_survey"
PROJECT_PATH="/scratch/brown/daminton/matija"
DELAY=3600
until false; do
   rsync -vah --progress --exclude={"swiftest_driver","*.swp","*~"}  "$PROJECT_PATH/$PROJECT_NAME" "$dest/"
   sleep $DELAY
done
