#!/bin/bash

#SBATCH --job-name=whatshap
#SBATCH --partition=ycga
#SBATCH --time=24:00:00
#SBATCH --mem=50G
##SBATCH --cpus-per-task=20
# Sets the output file name. %x = job-name, %j = job-id
#SBATCH --output=%x.%A_%a.slurm.out
#SBATCH --array=0-3
##SBATCH --mail-type=ALL

module purge
module load tabix
module load miniconda
conda activate pacbio

mkdir -p whatshap_output

#list files
VCFS=(./deepvariant_out_haplotagged_vcf/*.vcf.gz)

VCF=${VCFS[$SLURM_ARRAY_TASK_ID]}

# Extract the base name without extension for BAM file
BASENAME=$(basename $VCF .vcf.gz)

whatshap phase \
        -o ./whatshap_output/${BASENAME}_phased.vcf \
        --reference=/gpfs/gibbs/pi/ycga/mane/at2253/genome_ref/hg38_pbmm2/GRCh38_no_alt_analysis_set.fasta \
        $VCF \
        ./aligned/${BASENAME}.bam

echo "################### variant phasing complete #######################################"

#zip vcf and index
bgzip -c ./whatshap_output/${BASENAME}_phased.vcf > ./whatshap_output/${BASENAME}_phased.vcf.gz
tabix -p vcf ./whatshap_output/${BASENAME}_phased.vcf.gz

#specify new vcfs
VCFS=(./whatshap_output/${BASENAME}_phased.vcf.gz)
VCF=./whatshap_output/${BASENAME}_phased.vcf.gz

echo "VCFS: ${VCFS[@]}"
echo "VCF: $VCF"
echo "BASENAME: ${BASENAME}"

#run stats on each
whatshap stats \
$VCF \
--tsv=whatshap_output/${BASENAME}_whatshap.vcf.stats.tsv

echo "################### variant stats complete #######################################"
