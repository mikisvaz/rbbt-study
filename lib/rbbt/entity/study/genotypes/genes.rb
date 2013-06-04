module Study
  property :genes_with_overlapping_mutations => :single do
    mutations = cohort.metagenotype
    mutations.genes.compact.flatten.uniq
  end

  property :altered_isoforms => :single do
    mutated_isoforms = cohort.metagenotype.subset(relevant_mutations).mutated_isoforms.compact.flatten.uniq
    return [] if mutated_isoforms.empty?
    mutated_isoforms.select_by(:consequence){|c| c != "SYNONYMOUS"}
  end

  property :genes_with_altered_isoform_sequence => :single do
    altered_isoforms = self.altered_isoforms
    return [] if altered_isoforms.empty?
    altered_isoforms.transcript.compact.gene.uniq
  end

  property :damaged_isoforms => :single do |*args|
    altered_isoforms = self.altered_isoforms
    return [] if altered_isoforms.empty?
    altered_isoforms.select_by(:damaged?, *args)
  end

  property :genes_with_damaged_isoforms => :single do |*args|
    damaged_isoforms = damaged_isoforms(*args)
    return [] if damaged_isoforms.empty?
    damaged_isoforms.transcript.gene.uniq
  end

  property :genes_with_affected_splicing_sites => :single do
    cohort.metagenotype.subset(relevant_mutations).transcripts_with_affected_splicing.compact.flatten.uniq.gene.compact.uniq
  end

  property :affected_genes => :single do
    Gene.setup(genes_with_altered_isoform_sequence + genes_with_affected_splicing_sites, "Ensembl Gene ID", organism).uniq
  end

  property :damaged_genes => :single do |*args|
    Gene.setup((genes_with_damaged_isoforms(*args) + genes_with_affected_splicing_sites).uniq, "Ensembl Gene ID", organism)
  end

 property :samples_with_gene_damaged => :single do
    damaging_mutations= self.damaging_mutations

    samples_with_gene_damaged = {}
    cohort.each do |genotype|
      genotype.each do |mutation|
        next unless damaging_mutations.include? mutation
        genes = []
        mis = mutation.mutated_isoforms
        genes.concat mis.select_by(:damaged?).transcript.gene unless mis.nil? or mis.empty?
        genes.concat mutation.transcripts_with_affected_splicing.gene
        genes.uniq.each{|gene| samples_with_gene_damaged[gene] ||= []; samples_with_gene_damaged[gene] << genotype.jobname}
      end
    end
    samples_with_gene_damaged
  end

  property :samples_with_gene_affected => :single do
    relevant_mutations = self.relevant_mutations

    samples_with_gene_affected = {}
    cohort.each do |genotype|
      genotype.each do |mutation|
        next unless relevant_mutations.include? mutation
        genes = []
        mis = mutation.mutated_isoforms
        genes.concat mis.select_by(:consequence){|c| c != "SYNONYMOUS"}.transcript.gene unless mis.nil? or mis.empty?
        genes.concat mutation.transcripts_with_affected_splicing.gene
        genes.uniq.each{|gene| samples_with_gene_affected[gene] ||= []; samples_with_gene_affected[gene] << genotype.jobname}
      end
    end
    samples_with_gene_affected
  end

  property :__gene_sample_matrix => :single do
    tsv = TSV.setup({}, :key_field => "Ensembl Gene ID", :namespace => organism, :type => :list)
    samples = []
    i = 0
    num_samples = cohort.length

    cohort.each do |genotype|
      sample = genotype.jobname
      genotype.affected_genes.compact.flatten.uniq.each do |gene|
        tsv[gene] ||= ["FALSE"] * num_samples
        tsv[gene][i] = "TRUE"
      end
      samples << sample
      i += 1
    end

    tsv.fields = samples

    tsv
  end

  property :gene_sample_matrix => :single do
    genotyped_samples = samples.select{|s| s.has_genotype?}.sort

    tsv = TSV.setup({}, :key_field => "Ensembl Gene ID", :namespace => organism, :type => :list, :fields => genotyped_samples)

    num_samples = genotyped_samples.length
    genotyped_samples.each_with_index do |sample,i|
      sample.affected_genes.each do |gene|
        tsv[gene] ||= [false] * num_samples
        tsv[gene][i] = true
      end
    end

    tsv.fields = samples

    tsv
  end

  property :recurrent_genes => :single do |*args|
    min = args.first 
    min = 2 if min.nil?

    Gene.setup(samples_with_gene_affected.select{|gene, samples| samples.length >= min }.collect{|gene,samples| gene}, "Ensembl Gene ID", organism)
  end
end
