#!/bin/bash

i=guest
j=host

#Minimization-1
pmemd.cuda -O -i ${i}_min.in -p ${i}.prmtop -c ${i}_iso.rst7 -o ${i}_min.out -r ${i}_min.rst7 -ref ${i}_iso.rst7
pmemd.cuda -O -i ${j}_min.in -p ${j}.prmtop -c ${j}_iso.rst7 -o ${j}_min.out -r ${j}_min.rst7 -ref ${j}_iso.rst7
pmemd.cuda -O -i ${j}_${i}_min.in -p ${j}_${i}.prmtop -c ${j}_${i}_iso.rst7 -o ${j}_${i}_min.out -r ${j}_${i}_min.rst7 -ref ${j}_${i}_iso.rst7
pmemd.cuda -O -i all_min.in -p water.prmtop -c water_iso.rst7 -o water_min.out -r water_min.rst7

#Minimization-2
pmemd.cuda -O -i all_min.in -p ${i}.prmtop -c ${i}_min.rst7 -o ${i}_min2.out -r ${i}_min2.rst7
pmemd.cuda -O -i all_min.in -p ${j}.prmtop -c ${j}_min.rst7 -o ${j}_min2.out -r ${j}_min2.rst7
pmemd.cuda -O -i all_min.in -p ${j}_${i}.prmtop -c ${j}_${i}_min.rst7 -o ${j}_${i}_min2.out -r ${j}_${i}_min2.rst7

#Heating
pmemd.cuda -O -i nvt_md.in -c water_min.rst7 -p water.prmtop -o water_nvt.out -r water_nvt.rst7 -x water_nvt.nc
pmemd.cuda -O -i nvt_md.in -c ${i}_min2.rst7 -p ${i}.prmtop -o ${i}_nvt.out -r ${i}_nvt.rst7 -x ${i}_nvt.nc
pmemd.cuda -O -i nvt_md.in -c ${j}_min2.rst7 -p ${j}.prmtop -o ${j}_nvt.out -r ${j}_nvt.rst7 -x ${j}_nvt.nc
pmemd.cuda -O -i nvt_md.in -c ${j}_${i}_min2.rst7 -p ${j}_${i}.prmtop -o ${j}_${i}_nvt.out -r ${j}_${i}_nvt.rst7 -x ${j}_${i}_nvt.nc

#Equilibrating
pmemd.cuda -O -i npt_md.in -c water_nvt.rst7 -p water.prmtop -o water_npt.out -r water_npt.rst7 -x water_npt.nc
pmemd.cuda -O -i npt_md2.in -c water_npt.rst7 -p water.prmtop -o water_npt2.out -r water_npt2.rst7 -x water_npt2.nc

pmemd.cuda -O -i npt_md.in -c ${i}_nvt.rst7 -p ${i}.prmtop -o ${i}_npt.out -r ${i}_npt.rst7 -x ${i}_npt.nc
pmemd.cuda -O -i npt_md2.in -c ${i}_npt.rst7 -p ${i}.prmtop -o ${i}_npt2.out -r ${i}_npt2.rst7 -x ${i}_npt2.nc

pmemd.cuda -O -i npt_md.in -c ${j}_nvt.rst7 -p ${j}.prmtop -o ${j}_npt.out -r ${j}_npt.rst7 -x ${j}_npt.nc
pmemd.cuda -O -i npt_md2.in -c ${j}_npt.rst7 -p ${j}.prmtop -o ${j}_npt2.out -r ${j}_npt2.rst7 -x ${j}_npt2.nc

pmemd.cuda -O -i npt_md.in -c ${j}_${i}_nvt.rst7 -p ${j}_${i}.prmtop -o ${j}_${i}_npt.out -r ${j}_${i}_npt.rst7 -x ${j}_${i}_npt.nc
pmemd.cuda -O -i npt_md2.in -c ${j}_${i}_npt.rst7 -p ${j}_${i}.prmtop -o ${j}_${i}_npt2.out -r ${j}_${i}_npt2.rst7 -x ${j}_${i}_npt2.nc

vol=`grep VOL ${i}_npt2.out | head -n -2 | awk '{sum+=$9}END{printf "%10.7f\n",(sum/NR)^(1/3)}'`
cpptraj.cuda -p ${i}.prmtop -y ${i}_npt2.rst7 -x ${i}_prod.rst7
sed -i '$d' ${i}_prod.rst7
echo "  $vol  $vol  $vol  90.0000000  90.0000000  90.0000000" >> ${i}_prod.rst7

#Production
pmemd.cuda -O -i prod_md.in -c water_prod.rst7 -p water.prmtop -o water_prod1.out -r water_prod1.rst7 -x water_prod1.nc
pmemd.cuda -O -i prod_md.in -c ${i}_prod.rst7 -p ${i}.prmtop -o ${i}_prod1.out -r ${i}_prod1.rst7 -x ${i}_prod1.nc
pmemd.cuda -O -i prod_md.in -c ${j}_prod.rst7 -p ${j}.prmtop -o ${j}_prod1.out -r ${j}_prod1.rst7 -x ${j}_prod1.nc
pmemd.cuda -O -i prod_md.in -c ${j}_${i}_prod.rst7 -p ${j}_${i}.prmtop -o ${j}_${i}_prod1.out -r ${j}_${i}_prod1.rst7 -x ${j}_${i}_prod1.nc

c=`grep EPtot ${j}_${i}_prod1.out | head -n -2 | awk '{if(NR>100000)sum+=$9}END{printf "%14.6f\n",sum/(NR-100000)}'`
w=`grep EPtot water_prod1.out | head -n -2 | awk '{if(NR>100000)sum+=$9}END{printf "%14.6f\n",sum/(NR-100000)}'`
h=`grep EPtot ${j}_prod1.out | head -n -2 | awk '{if(NR>100000)sum+=$9}END{printf "%14.6f\n",sum/(NR-100000)}'`
g=`grep EPtot ${i}_prod1.out | head -n -2 | awk '{if(NR>100000)sum+=$9}END{printf "%14.6f\n",sum/(NR-100000)}'`;
dH=`echo "$c $w $h $g"|awk '{print $1 + $2 - $3 - $4}'`
echo "Binding Enthalpy (kcal/mol) = $dH"
