version 1.0

task tar_asm {
  input {
    File ref
    File hapOne
    File hapTwo
    String sample
    String threads
    String mem_gb
  }
  command <<<
    set -eux
    mkdir -p asm/~{sample}
    cp ~{ref} asm/ref.fa
    samtools faidx asm/ref.fa
    cp ~{hapOne} asm/~{sample}/h1.fa.gz
    cp ~{hapTwo} asm/~{sample}/h2.fa.gz
    tar zcvf asm.tgz asm/
  >>>
  output {
    File asm_tar = "asm.tgz"
  }
  ############################
  runtime {
      cpu:            threads
      memory:         mem_gb + " GiB"
      disks:          "local-disk " + 1000 + " HDD"
      bootDiskSizeGb: 50
      preemptible:    3
      maxRetries:     1
      docker:         "us.gcr.io/broad-dsp-lrma/lr-pav:1.2.1"
  }
}

task call_final_bed {
  input {
    File pav_conf
    File pav_asm
    File invBed
    File insBed
    File delBed
    File snvBed
    String threads
    String mem_gb
    String sample
  }
  command <<<
    source activate lr-pav
    set -eux
    cp ~{pav_conf} ./config.json
    tar zxvf ~{pav_asm}
    tar zxvf ~{invBed}
    tar zxvf ~{snvBed}
    tar zxvf ~{insBed}
    tar zxvf ~{delBed}
    mv /opt/pav /cromwell_root/
    tree
    snakemake -s pav/Snakefile --cores ~{threads} results/~{sample}/bed/snv_snv.bed.gz results/~{sample}/bed/indel_ins.bed.gz results/~{sample}/bed/indel_del.bed.gz results/~{sample}/bed/sv_ins.bed.gz results/~{sample}/bed/sv_del.bed.gz results/~{sample}/bed/sv_inv.bed.gz results/~{sample}/bed/fa/indel_ins.fa.gz results/~{sample}/bed/fa/indel_del.fa.gz results/~{sample}/bed/fa/sv_ins.fa.gz results/~{sample}/bed/fa/sv_del.fa.gz results/~{sample}/bed/fa/sv_inv.fa.gz
  >>>
  output {
    Array[File] snakemake_logs = glob(".snakemake/log/*.snakemake.log")
    File snvBedOut = "results/~{sample}/bed/snv_snv.bed.gz"
    File indelInsBed = "results/~{sample}/bed/indel_ins.bed.gz"
    File indelDelBed = "results/~{sample}/bed/indel_del.bed.gz"
    File svInsBed = "results/~{sample}/bed/sv_ins.bed.gz"
    File svDelBed = "results/~{sample}/bed/sv_del.bed.gz"
    File invBedOut = "results/~{sample}/bed/sv_inv.bed.gz"
    File indelInsFasta = "results/~{sample}/bed/fa/indel_ins.fa.gz"
    File indelDelFasta = "results/~{sample}/bed/fa/indel_del.fa.gz"
    File svInsFasta = "results/~{sample}/bed/fa/sv_ins.fa.gz"
    File svDelFasta = "results/~{sample}/bed/fa/sv_del.fa.gz"
    File invFasta = "results/~{sample}/bed/fa/sv_inv.fa.gz"
  }
  ############################
  runtime {
      cpu:            threads
      memory:         mem_gb + " GiB"
      disks:          "local-disk " + 1000 + " HDD"
      bootDiskSizeGb: 50
      preemptible:    3
      maxRetries:     1
      docker:         "us.gcr.io/broad-dsp-lrma/lr-pav:1.2.1"
  }
}
