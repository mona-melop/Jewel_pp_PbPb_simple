import yoda
import numpy as np
import matplotlib.pyplot as plt

# Useful documentation:
# YODA: https://yoda.hepforge.org/pydoc/
# MATPLOTLIB: https://matplotlib.org/
# NUMPY: https://numpy.org/doc/

# Don't forget to load necessary packages in SAMPA
# source /cvmfs/alice.cern.ch/etc/login.sh
# eval `alienv printenv VO_ALICE@Rivet::2.7.2-alice2-1`

yodapp = '/sampa/archive/monalisa/Mestrado/yoda_merge/pp_poseidon_raa_R0.2.yoda'
yodaPbPb = '/sampa/archive/monalisa/Mestrado/yoda_merge/Pb_poseidon_raa_R0.2.yoda'
obs = '/RAA_ATLAS/JetpT_R0.2' 

histos_pp = yoda.read(yodapp)
histos_PbPb = yoda.read(yodaPbPb)

pp_jet = histos_pp[obs]
PbPb_jet = histos_PbPb[obs]


pp_evtc = histos_pp['/_EVTCOUNT'].sumW()
pp_xsec = histos_pp['/_XSEC'].point(0).x
pp_jet.scaleW(pp_xsec / pp_evtc)




PbPb_evtc = histos_PbPb['/_EVTCOUNT'].sumW()
PbPb_xsec = histos_PbPb['/_XSEC'].point(0).x
PbPb_jet.scaleW(PbPb_xsec / PbPb_evtc)

raa = PbPb_jet / pp_jet


x = np.asarray(raa.xVals())
y = np.asarray(raa.yVals())
yerr = np.asarray((raa.yMaxs() - raa.yMins()) / 2)
xerr = np.asarray((raa.xMaxs() - raa.xMins()) / 2)


# Define plot
plt.figure(1)
plt.errorbar(x, y, yerr, xerr, fmt='o')
#plt.yscale('log') 
#plt.xscale('log')
plt.xlabel('p_T [GeV]')
plt.ylabel('R_{AA}')
plt.title('Glauber+Bjorken')




# Save
plt.savefig('poseidon_raa.pdf')
# run: 'display [name_plot]' to see final result 
