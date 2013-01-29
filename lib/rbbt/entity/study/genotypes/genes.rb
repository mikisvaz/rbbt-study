module Study
  property :genes_with_overlapping_mutations => :single do
    mutations = cohort.metagenotype
    mutations.genes.compact.flatten.uniq
  end

  property :altered_isoforms => :single do
    cohort.metagenotype.mutated_isoforms.compact.flatten.uniq.select_by(:consequence){|c| c != "SYNONYMOUS"}
  end

  property :genes_with_altered_isoform_sequence => :single do
    altered_isoforms.transcript.compact.gene.uniq
  end

  property :damaged_isoforms => :single do |*args|
    altered_isoforms.select_by(:damaged?, *args)
  end

  property :genes_with_damaged_isoforms => :single do |*args|
    damaged_isoforms(*args).transcript.gene.uniq
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

  property :recurrent_genes => :single do |*args|
    min = args.first 
    min = 2 if min.nil?

    Gene.setup(samples_with_gene_affected.select{|gene, samples| samples.length >= min }.collect{|gene,samples| gene}, "Ensembl Gene ID", organism)
  end
end
