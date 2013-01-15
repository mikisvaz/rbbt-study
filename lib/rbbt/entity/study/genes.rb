# NON UNIQ
returns "Ensembl Gene ID"
task :affected_genes => :annotations do
  Gene.setup(study.cohort.collect{|genotype| genotype.genes.compact}.flatten, "Ensembl Gene ID", organism)
end

# NON UNIQ
dep :relevant_mutations
returns "Ensembl Gene ID"
task :relevant_genes => :annotations do
  relevant_mutations = step(:relevant_mutations).load
  genes = relevant_mutations.collect{|mutation|
    splicing = mutation.in_exon_junction? ? mutation.transcripts_with_affected_splicing.gene : []
    protein = (mis = mutation.mutated_isoforms).nil? ? [] : mis.protein.gene.compact.uniq
    (splicing + protein).uniq
  }.compact.flatten
  Gene.setup(genes, "Ensembl Gene ID", organism)
end

# NON UNIQ
dep :relevant_mutations
returns "Ensembl Gene ID"
input :methods, :array, "Damage prediction methods", [:sift, :mutation_assessor]
input :add_exon_junction, :boolean, "Add exon junction mutations", true
task :damaged_genes => :annotations do |methods, add_exon_junction|
  relevant_mutations = step(:relevant_mutations).load
  all_mis = relevant_mutations.mutated_isoforms.compact.flatten
  mi_damaged = Misc.process_to_hash(all_mis){|all_mis| all_mis.damaged?(methods) }

  genes = relevant_mutations.collect{|mutation|
    genes = []

    genes.concat mutation.transcripts_with_affected_splicing.gene if add_exon_junction and mutation.in_exon_junction? and mutation.type != 'none'

    mis = mutation.mutated_isoforms
    genes.concat mis.select{|mi| mi_damaged[mi]}.protein.gene.compact.uniq unless mis.nil?

    genes.uniq
  }.compact.flatten

  Gene.setup(genes, "Ensembl Gene ID", organism)
end

dep :relevant_genes
task :gene_mutation_count => :yaml do
  relevant_genes = step(:relevant_genes).load
  if relevant_genes.any?
    Misc.counts(relevant_genes.clean_annotations)
  else
    {}
  end
end

# NON UNIQ
dep :gene_mutation_count
input :percentage, :float, "Minimum percentage of samples with the mutation", 0
returns "Ensembl Gene ID"
task :recurrent_genes => :annotations do |percentage|
  gene_mutation_count = step(:gene_mutation_count).load
  minimum = (study.cohort.length.to_f * percentage.to_f) / 100.0

  genes = gene_mutation_count.select{|gene, count| 
    
    count > 1 and count > minimum 
  
  }.collect{|gene, count| gene}

  Gene.setup(genes, "Ensembl Gene ID", organism)
end

dep :damaged_genes
dep :recurrent_genes
returns "Ensembl Gene ID"
task :suspect_genes => :annotations do
  damaged_genes = step(:damaged_genes).load
  recurrent_genes = step(:recurrent_genes).load

  Gene.setup(( damaged_genes + recurrent_genes ).flatten.uniq, "Ensembl Gene ID", organism)
end

dep :relevant_mutations
dep :recurrent_genes
task :mutations_over_recurrent_genes => :annotations do
  relevant_mutations = step(:relevant_mutations).load
  recurrent_genes = step(:recurrent_genes).load

  relevant_mutations.select{|mutation| mutation.genes and (mutation.genes & recurrent_genes).any?}
end

dep :relevant_mutations
dep :suspect_genes
task :mutations_over_suspect_genes => :annotations do
  relevant_mutations = step(:relevant_mutations).load
  suspect_genes = step(:suspect_genes).load

  relevant_mutations.select{|mutation| mutation.genes and (mutation.genes & suspect_genes).any?}
end

require 'rbbt/mutation/oncodriveFM'
task :oncodriveFM => :tsv do
  tsv = OncodriveFM.process_cohort(study.cohort)
  tsv.namespace = organism
  tsv
end
