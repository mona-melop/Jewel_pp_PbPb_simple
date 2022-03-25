#!/bin/bash



# Adapted from Fabio's example script
# This script prepares the environment to run pp at 5.02 TeV
# $1 = number of the job and determines which medium profile to use
# $2 = code identification of the run
# $3 = analysis only mode


# Load enviroment
source /cvmfs/alice.cern.ch/etc/login.sh
eval `alienv printenv VO_ALICE@GSL::v1.16-25`
eval `alienv printenv VO_ALICE@Rivet::2.7.2-alice2-1`
cd /sampa/monalisa/Jets/pp_5020



# Arguments
NJOB=$1
CODE=$2$1

ANA_MODE=$3

echo "$(date)"
echo "JEWEL vacuum for pp 5.02 TeV with:"
echo "NJOB = "$1
echo "CODE = "$CODE
echo "ANALYSIS ONLY MODE = "$ANA_MODE



# Exporting enviroment variables necessary for the run
export HEPMC_FILE="/sampa/archive/monalisa/Mestrado/results/hepmc/"$CODE".hepmc"
export YODA_SHAPE="/sampa/archive/monalisa/Mestrado/results/yoda/"$CODE"_shape.yoda"
export YODA_RAA="/sampa/archive/monalisa/Mestrado/results/yoda/"$CODE"_raa.yoda"             
export TEMP_DIR="/sampa/archive/monalisa/Mestrado/temp"

export PAR_FILE=$TEMP_DIR/par_"$CODE".dat



# Skip all if analysis mode is enabled
if [ "$ANA_MODE" = "0" ]; then

	# Prepare parameters file
	echo "Preparing parameters file @ " $PAR_FILE
	cp /sampa/monalisa/Jets/pp_5020/par.dat $PAR_FILE


	sed -i "$ a NJOB $1" $PAR_FILE
	sed -i "$ a LOGFILE /sampa/archive/monalisa/Mestrado/results/hepmc/"$CODE".log" $PAR_FILE
	sed -i "$ a HEPMCFILE $HEPMC_FILE" $PAR_FILE
	sed -i "$ a XSECFILE $TEMP_DIR/xsec_$CODE.dat" $PAR_FILE
	sed -i "$ a SPLITINTFILE $TEMP_DIR/splitint_$CODE.dat" $PAR_FILE
	sed -i "$ a PDFFILE $TEMP_DIR/pdf_$CODE.dat" $PAR_FILE


	# Execute jewel
	echo "Executing Jewel"
	echo $PAR_FILE
        $JEWEL_PATH/./jewel-2.2.0-vac $PAR_FILE
	echo  "Jewel Done"


	# Remove all temporary generated files
	rm $PAR_FILE
	rm $TEMP_DIR/xsec_$CODE.dat
	rm $TEMP_DIR/splitint_$CODE.dat
	rm $TEMP_DIR/pdf_$CODE.dat

# Analysis mode only needs .hepmc from previous run
else
	echo "Analysis mode"
	gzip -d $HEPMC_FILE.gz
fi



# Rivet
export MAXETA=0.7
export PSI2=0
export PSI3=0
export PSI4=0
export PSI=0

echo -e "Executing Rivet with: PSI2 = $PSI2 \t PSI3 = $PSI3 \t PSI4 = $PSI4"
#rivet -a JET_SHAPE --ignore-beams -H $YODA_SHAPE $HEPMC_FILE

for RJETS in 0.2 0.3 0.4 0.6 0.8 1.0
#for RJETS in 0.2 0.4
do
        export RJETS
        YODA_RAAR="/sampa/archive/monalisa/Mestrado/results/yoda/"$CODE"_raa_R"$RJETS".yoda"
        YODA_VNR="/sampa/archive/monalisa/Mestrado/results/yoda/"$CODE"_vnatlas_R"$RJETS".yoda"
	YODA_EXTRAR="/sampa/archive/monalisa/Mestrado/results/yoda/"$CODE"_extra_R"$RJETS".yoda"
	YODA_PHIR="/sampa/archive/monalisa/Mestrado/results/yoda/"$CODE"_phi_R"$RJETS".yoda"
        
	#cd /sampa/monalisa/Jets/rivetanalises/
	#rivet-buildplugin RivetRAA_ATLAS.so RAA_ATLAS.cc 
	rivet -a RAA_ATLAS --ignore-beams -H $YODA_RAAR $HEPMC_FILE
	


	#rivet -a EXTRA --ignore-beam -H $YODA_EXTRAR $HEPMC_FILE
	#rivet -a PHI_PLANE --ignore-beam -H $YODA_PHIR $HEPMC_FILE
        #rivet -a VN_ATLAS --ignore-beams -H $YODA_VNR $HEPMC_FILE

        YODA_RAAR_TEST="/sampa/archive/monalisa/Mestrado/results/yoda/"$CODE"_raatest_R"$RJETS".yoda"
        #YODA_VNR_TEST="/sampa/archive/monalisa/Mestrado/results/yoda/"$CODE"_vnatlastest_R"$RJETS".yoda"
        #rivet -a JET_TEST --ignore-beams -H $YODA_RAAR_TEST $HEPMC_FILE
        #rivet -a VN_ATLAS_TEST --ignore-beams -H $YODA_VNR_TEST $HEPMC_FILE
done



# Finish by compressing generated results
echo "Done with Rivet! Compressing .hepmc file"
gzip $HEPMC_FILE
#rm $HEPMC_FILE


# Variable check
echo -e "\n\nVariable report:"
echo "NJOB = $NJOB"
echo "HEPMC_FILE = $HEPMC_FILE"
echo $(date)
