dep :mutated_genes_per_sample
input :list, :array, "Gene list in Ensembl Gene ID"
task :gene_features => :tsv do |list|
  mutated_genes_per_sample = step(:mutated_genes_per_sample).load


  samples = study.cohort.fields
  fields = list.name.collect{|n| n + "_mut"}
  table = TSV.setup({}, :key_field => "Sample", :fields => fields)

  samples.each do |sample|
    affected_genes = mutated_genes_per_sample[sample] || []
    table[sample] = list.collect{|gene| affected_genes.include?(gene)? 1 : 0}
  end

  table
end
