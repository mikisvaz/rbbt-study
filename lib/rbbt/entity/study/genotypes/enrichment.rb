require 'rbbt/workflow'

Workflow.require_workflow "MutationEnrichment"
module StudyWorkflow

  #{{{ SAMPLE ENRICHMENT
  input :database, :string
  input :mutation_subset, :select, "Mutation subset to use", :relevant_mutations
  input :baseline, :select, "Type of baseline to use", :pathway_base_counts, :select_options => [:pathway_base_counts, :pathway_gene_counts]
  input :permutations, :integer, "Number of permutations in test", 10000
  input :fdr, :boolean, "BH FDR corrections", true
  input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
  task :sample_pathway_enrichment => :tsv do |database,mutation_subset,baseline,permutations,fdr,masked_genes|

    mutations = study.send(mutation_subset)

    mutation_tsv = TSV.setup({}, :key_field => "Genomic Mutation", :fields => ["Sample"], :type => :flat)

    study.cohort.each do |genotype|
      sample = genotype.jobname
      genotype.each do |mutation|
        next unless mutations.include? mutation
        mutation_tsv[mutation] ||= []
        mutation_tsv[mutation] << sample
      end
    end

    job = MutationEnrichment.job(:sample_pathway_enrichment, study, 
                                 :mutations => mutation_tsv, :database => database, :baseline => baseline, :fdr => fdr, 
                                 :masked_genes => masked_genes, :organism => study.organism, :permutations => permutations)

    res = job.run
    set_info :total_covered, job.info[:total_covered]
    set_info :covered_mutations, job.info[:covered_mutations]
    res
  end

  #{{{ METAGENOTYPE ENRICHMENT
  input :database, :string
  input :mutation_subset, :select, "Mutation subset to use", :relevant_mutations
  input :baseline, :select, "Type of baseline to use", :pathway_base_counts, :select_options => [:pathway_base_counts, :pathway_gene_counts]
  input :fdr, :boolean, "BH FDR corrections", true
  input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
  task :mutation_pathway_enrichment => :tsv do |database,mutation_subset,baseline,fdr,masked_genes,organism|

    mutations = study.send(mutation_subset)

    job = MutationEnrichment.job(:mutation_pathway_enrichment, study, 
                                 :mutations => mutations, :database => database, :baseline => baseline, :fdr => fdr, 
                                 :masked_genes => masked_genes, :organism => study.organism)
    res = job.run
    set_info :total_covered, job.info[:total_covered]
    set_info :covered_mutations, job.info[:covered_mutations]
    res
  end
end
