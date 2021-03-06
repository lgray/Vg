#!/bin/bash

postfix=(
    `cat inputs_to_process.txt`
)

mass=$1

cards=""
for name in ${postfix[@]}
do
    echo building datacard for $name
    dirName="info_${mass}_${name}"
    dcardName="datacard_${mass}_${name}.txt"
    bgLogName="data_${name}_bkg.log"
    sig_norm=`grep 'norm =' ${dirName}/index.html | awk '{print $3}'`    
    bkg_norm=`grep ' Background number of events = ' ${dirName}/${bgLogName} | awk '{print $6}'`
    
    #let's build a datacard!
    cat > ${dirName}/${dcardName} <<EOF
imax 1 number of channels
jmax * number of backgrounds
kmax * number of systematic uncertainty sources
----------
shapes signal     Vg w_signal_${mass}.root      Vg:signal_fixed_${name}
shapes background Vg w_background_GaussExp.root Vg:bg_${name}
shapes data_obs   Vg w_data.root                Vg:data_obs
----------
## Observation
bin                     Vg
observation             -1
----------
bin                   Vg          Vg
process               signal      background
process               0           1
rate                  ${sig_norm} 1
cms_lumi_13TeV  lnN   1.027       -     
cms_btag_sf_13TeV       lnN              0.833       -         
cms_btag_sf_13TeV       lnN              1.2         -
cms_JES_13TeV           lnN              1.02        -         
cms_phoHLT_13TeV        lnN              1.03        -         
cms_pho_sf_13TeV        lnN              1.02        -         
cms_pileup_13TeV        lnN              1.05        -         
cms_xzg_pdf_13TeV       lnN              1.04        -         
cms_xzg_scale_13TeV     lnN              1.06        -        
EOF

    
    #now add the systematics to the card
    #grep 'signal_' ${dirName}/index.html | awk '{print $1 " " $2 " " $3 " " $4}' >>  ${dirName}/${dcardName}
    #grep 'bg_' ${dirName}/${bgLogName} | grep 'param' >> ${dirName}/${dcardName}
    if [[ $dcardName == *"anti"* ]]
    then
	sed -i 's/WHATKIND/Anti/' ${dirName}/${dcardName}
	sed -i '/cms_btag_sf_13TeV.*1\.2.*/d' ${dirName}/${dcardName}
	grep 'bg_' ${dirName}/${bgLogName} | grep 'param' >> ${dirName}/${dcardName}
    else
	sed -i 's/WHATKIND//' ${dirName}/${dcardName}
	sed -i '/cms_btag_sf_13TeV.*0.833.*/d' ${dirName}/${dcardName}
    fi

    cards+="${dirName}/${dcardName} "
done

combineCards.py -S $cards > datacard_qqg_${mass}_combined.txt

