#!/bin/bash


# Adapted from Fabio's example script
# This script prepares the environment to run JEWEL Default PbPb at 5.02 TeV
# $1 = number of the job and determines which medium profile to use
# $2 = code identification of the run
# $3 = MDSCALEFAC (JEWEL free parameter) used (default 0.9)
# $4 = TC (crititical temperature, default 0.17)
# $5 = centrality, must match one of: 0-10, 10-20, 20-40, 40-60, 60-80 (default 0-10)
# $6 = analysis mode, if 1 runs only rivet analyses (default 0)



# Load enviroment
source /cvmfs/alice.cern.ch/etc/login.sh
eval `alienv printenv VO_ALICE@GSL::v1.16-25`
eval `alienv printenv VO_ALICE@Rivet::2.7.2-alice2-1`
cd /sampa/mariammp/Jets/PbPb_5020



# Arguments
NJOB=`python -c "print($1 % 1000)"`
CODE=$2$1
MDS=${3:-0.9}
TC=${4:-0.16}
CENT=${5:-0-10}
ANA_MODE=${6:-0}

echo "$(date)"
echo "JEWEL Default for PbPb 5.02 TeV with:"
echo "NJOB = "$1
echo "CODE = "$CODE
echo "MDSCALEFAC = "$MDS
echo "CENTRALITY = "$CENT
echo "TC = "$TC
echo "ANALYSIS ONLY MODE = "$ANA_MODE



# Exporting enviroment variables necessary for the run
export HEPMC_FILE="/sampa/mariammp/Jets/PbPb_5020/results/hepmc/"$CENT"/"$CODE".hepmc"
export YODA_SHAPE="/sampa/mariammp/Jets/PbPb_5020/results/yoda/"$CENT"/"$CODE"_shape.yoda"
export YODA_VN="/sampa/mariammp/Jets/PbPb_5020/results/yoda/"$CENT"/"$CODE"_vn.yoda"
export YODA_VNATLAS="/sampa/mariammp/Jets/PbPb_5020/results/yoda/"$CENT"/"$CODE"_vnatlas.yoda"
export YODA_RAA="/sampa/mariammp/Jets/PbPb_5020/results/yoda/"$CENT"/"$CODE"_raa.yoda"

export TEMP_DIR="/sampa/mariammp/Jets/PbPb_5020/temp/$CENT"
export PAR_FILE=$TEMP_DIR/parsimple_"$CODE".dat
export PAR_MED_FILE=$TEMP_DIR/medparsimple_"$CODE".dat



# Skip all if analysis mode is enabled
if [ "$ANA_MODE" = "0" ]; then

	# Prepare parameters file
	echo "Preparing parameters file @ " $PAR_FILE
	cp $CENT/par_simple_preset.dat $PAR_FILE


	sed -i "$ a NJOB $1" $PAR_FILE
	sed -i "$ a LOGFILE /sampa/mariammp/Jets/PbPb_5020/results/hepmc/"$CENT"/"$CODE".log" $PAR_FILE
	sed -i "$ a HEPMCFILE $HEPMC_FILE" $PAR_FILE
	sed -i "$ a XSECFILE $TEMP_DIR/xsec_$CODE.dat" $PAR_FILE
	sed -i "$ a SPLITINTFILE $TEMP_DIR/splitint_$CODE.dat" $PAR_FILE
	sed -i "$ a PDFFILE $TEMP_DIR/pdf_$CODE.dat" $PAR_FILE
	sed -i "$ a MEDIUMPARAMS $PAR_MED_FILE" $PAR_FILE



	# Prepare medium file
	echo "Preparing medium file @ " $PAR_MED_FILE

	cp $CENT/medpar_simple.dat $PAR_MED_FILE
	sed -i "$ a MDSCALEFAC $MDS" $PAR_MED_FILE
	sed -i "$ a TC $TC" $PAR_MED_FILE


	# Execute jewel
	echo "Executing Jewel"
	$JEWEL_PATH/./jewel-2.2.0-simple $PAR_FILE



	# Remove all temporary generated files
	rm $PAR_FILE
	rm $PAR_MED_FILE
	rm $TEMP_DIR/xsec_$CODE.dat
	rm $TEMP_DIR/splitint_$CODE.dat
	rm $TEMP_DIR/pdf_$CODE.dat

# Analysis mode only needs .hepmc from previous run
else
	echo "Analysis mode"
	#unxz $HEPMC_FILE.xz
fi


# Check if par_med_file was really loaded 
if grep -Fxq " No medium parameter file found, will run with default settings." /sampa/mariammp/Jets/PbPb_5020/results/hepmc/"$CENT"/"$CODE".log
then
        echo "Error at loading medium parameter file, skip analysis!"
else
	echo "Starting Rivet"
	# Rivet
	export PSI2=0
	export PSI3=0
	export PSI4=0
	export PSI=0

	echo -e "Executing Rivet with: PSI2 = $PSI2 \t PSI3 = $PSI3 \t PSI4 = $PSI4"
	rivet -a JET_SHAPE --ignore-beams -H $YODA_SHAPE $HEPMC_FILE
	#rivet -a JET_VN --ignore-beams -H $YODA_VN $HEPMC_FILE

	for RJETS in 0.2 0.3 0.4 0.6 0.8 1.0
	#for RJETS in 0.2
	do
		export RJETS
	        YODA_RAAR="/sampa/mariammp/Jets/PbPb_5020/results/yoda/"$CENT"/"$CODE"_raa_R"$RJETS".yoda"
	        YODA_VNR="/sampa/mariammp/Jets/PbPb_5020/results/yoda/"$CENT"/"$CODE"_vnatlas_R"$RJETS".yoda"
	        rivet -a RAA_ATLAS --ignore-beams -H $YODA_RAAR $HEPMC_FILE
		#rivet -a VN_ATLAS --ignore-beams -H $YODA_VNR $HEPMC_FILE
	done
	
	echo "Done with Rivet! Compressing .hepmc file"
fi



# Finish by compressing generated results
#xz $HEPMC_FILE
rm $HEPMC_FILE



# Variable check
echo -e "\n\nVariable report:"
echo "NJOB = $NJOB"
#echo "PSI2 = $PSI"
#echo "PSI3 = $PSI3"
#echo "PSI4 = $PSI4"
echo "YODA_SHAPE = $YODA_RAA"
echo "HEPMC_FILE = $HEPMC_FILE"
echo "$(date)"
