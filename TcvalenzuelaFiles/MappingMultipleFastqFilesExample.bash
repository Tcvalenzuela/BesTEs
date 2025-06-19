#!/bin/bash

#SBATCH --time=168:00:00 # Job time limit
#SBATCH -J TamponbwaFreely # Job name
#SBATCH -o %x_%j.out # Output file name
#SBATCH -e %x_%j.err # Error file name
#SBATCH --cpus-per-task=32 # Number of CPUs on the same node
#SBATCH --mem=100G # Memory reservation
#SBATCH --constraint='haswell|broadwell|skylake' 
#SBATCH --exclude=pbil-deb27 # Exclude specific nodes

# Paths
Fastq="/beegfs/project/mosquites/aalbo1200g/Fastq"
reference="/beegfs/data/tcarrasco/Reference/GCF_035046485.1_AalbF5_genomic.fna"

# Load environment
source /beegfs/home/tcarrasco/.bashrc
source /beegfs/data/tcarrasco/Programs/Conda/etc/profile.d/conda.sh
conda init
conda activate base  # Replace 

# Change directory to Fastq
cd $Fastq

# Loop through files
for file in $Fastq/Tampon/15x/*_NoDup_15x_1.fq.gz; do
    sname=$(basename "$file" | sed 's/_NoDup_15x_1.fq.gz//g')  # Extract sample name
    conda activate base
    # Check if BAM file already exists
    if [ -e "${sname}MapFreely_sorted.bam" ]; then
        continue
    fi
    
    # Define R1 and R2 paths
    R1="$file"
    R2="${file/_NoDup_15x_1.fq.gz/_NoDup_15x_2.fq.gz}"  # Replace `_1` with `_2` for the second pair

    # Run BWA-MEM2 and process output
    bwa-mem2 mem -t 32 $reference $R1 $R2 > ${sname}MapFreely.sam
    samtools view -b ${sname}MapFreely.sam > ${sname}MapFreely.bam
    samtools sort ${sname}MapFreely.bam -o ${sname}MapFreely_sorted.bam
    samtools index ${sname}MapFreely_sorted.bam
    
    # Clean up intermediate files
    rm ${sname}MapFreely.sam ${sname}MapFreely.bam
    conda activate Piccard
    picard CollectInsertSizeMetrics I=${sname}MapFreely_sorted.bam O=${sname}insert_size_metrics.txt H=${sname}insert_size_histogram.pdf M=0.5
    rm ${sname}MapFreely_sorted.bam
done
