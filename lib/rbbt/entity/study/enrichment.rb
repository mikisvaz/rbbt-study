#{{{ SAMPLE ENRICHMENT
dep do |jobname, inputs| job(inputs[:mutation_subset] || :relevant_mutations, jobname, inputs) end
input :database, :string
input :mutation_subset, :select, "Mutation subset to use", :relevant_mutations
input :baseline, :select, "Type of baseline to use", :bases, :select_options => [:pathway_base_counts, :pathway_gene_counts]
input :permutations, :integer, "Number of permutations in test", 10000
input :fdr, :boolean, "BH FDR corrections", true
input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
input :organism, :string, "Organism code", metadata[:organism]
task :sample_pathway_enrichment => :tsv do |database,mutation_subset,baseline,permutations,fdr,masked_genes,organism|

  mutations = step(mutation_subset).load

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
                               :masked_genes => masked_genes, :organism => organism, :permutations => permutations)

  res = job.run
  set_info :total_covered, job.info[:total_covered]
  set_info :covered_mutations, job.info[:covered_mutations]
  res
end

#{{{ METAGENOTYPE ENRICHMENT
dep do |jobname, inputs| job(inputs[:mutation_subset] || :relevant_mutations, jobname, inputs) end
input :database, :string
input :mutation_subset, :select, "Mutation subset to use", :relevant_mutations
input :baseline, :select, "Type of baseline to use", :pathway_base_counts, :select_options => [:pathway_base_counts, :pathway_gene_counts]
input :fdr, :boolean, "BH FDR corrections", true
input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
input :organism, :string, "Organism code", metadata[:organism]
task :mutation_pathway_enrichment => :tsv do |database,mutation_subset,baseline,fdr,masked_genes,organism|

  mutations = step(mutation_subset).load

  job = MutationEnrichment.job(:mutation_pathway_enrichment, study, 
                               :mutations => mutations, :database => database, :baseline => baseline, :fdr => fdr, 
                               :masked_genes => masked_genes, :organism => organism)
  res = job.run
  set_info :total_covered, job.info[:total_covered]
  set_info :covered_mutations, job.info[:covered_mutations]
  res
end
 





################################################################
#{{{ OLD
################################################################

#{{{ BASE AND GENE COUNTS

#input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
#input :organism, :string, "Organism code", metadata[:organism]
#task :pathway_base_counts => :tsv do |masked_genes, organism|
#  database = clean_name
#  log :loading_genes, "Loading genes from #{ database } #{ organism }"
#  case database
#  when 'kegg'
#    tsv = KEGG.gene_pathway.tsv :key_field => "KEGG Pathway ID", :fields => ["KEGG Gene ID"], :type => :flat, :persist => true, :merge => true
#    total_genes = Gene.setup(tsv.values.compact.flatten.uniq, "KEGG Gene ID", organism).ensembl.compact
#  when 'go', 'go_bp'
#    tsv = Organism.gene_go_bp(organism).tsv :key_field => "GO ID", :fields => ["Ensembl Gene ID"], :type => :flat, :persist => true, :merge => true
#    total_genes = Gene.setup(tsv.values.compact.flatten.uniq, "Ensembl Gene ID", organism).ensembl.compact
#  when 'pfam'
#    tsv = Organism.gene_pfam(organism).tsv :key_field => "Pfam Domain", :fields => ["Ensembl Gene ID"], :type => :flat, :persist => true, :merge => true
#    total_genes = Gene.setup(tsv.values.compact.flatten.uniq, "Ensembl Gene ID", organism).ensembl.compact
#  end
#
#  tsv.namespace = organism
#
#  counts = TSV.setup({}, :key_field => tsv.key_field, :fields => ["Bases"], :type => :single, :cast => :to_i, :namespace => organism)
#
#  log :processing_database, "Processing database #{database}"
#  tsv.with_monitor do
#    tsv.through do |pathway, genes|
#      next if genes.nil? or genes.empty? 
#      size = Gene.gene_list_exon_bases(genes.ensembl.compact.remove(masked_genes))
#      counts[pathway] = size
#    end
#  end
#
#  log :computing_exome_size, "Computing number of exome bases covered by pathway annotations"
#  total_size = Gene.gene_list_exon_bases(total_genes.remove(masked_genes))
#
#  set_info :total_size, total_size
#  set_info :total_gene_list, total_genes.remove(masked_genes)
#
#  counts
#end
#
#input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
#input :organism, :string, "Organism code", metadata[:organism]
#task :pathway_gene_counts => :tsv do |masked_genes,organism|
#  database = clean_name
#  case database.to_s
#  when 'kegg'
#    tsv = KEGG.gene_pathway.tsv :key_field => "KEGG Pathway ID", :fields => ["KEGG Gene ID"], :type => :flat, :persist => true, :merge => true
#    total_genes = Gene.setup(tsv.values.compact.flatten.uniq, "KEGG Gene ID", organism).ensembl.compact
#  when 'go', 'go_bp'
#    tsv = Organism.gene_go_bp(organism).tsv :key_field => "GO ID", :fields => ["Ensembl Gene ID"], :type => :flat, :persist => true, :merge => true
#    total_genes = Gene.setup(tsv.values.compact.flatten.uniq, "Ensembl Gene ID", organism).ensembl.compact
#  when 'pfam'
#    tsv = Organism.gene_pfam(organism).tsv :key_field => "Pfam Domain", :fields => ["Ensembl Gene ID"], :type => :flat, :persist => true, :merge => true
#    total_genes = Gene.setup(tsv.values.compact.flatten.uniq, "Ensembl Gene ID", organism).ensembl.compact
#  end
#
#  counts = TSV.setup({}, :key_field => tsv.key_field, :fields => ["Genes"], :type => :single, :cast => :to_i, :namespace => organism)
#
#  tsv.through do |pathway, genes|
#    next if genes.nil? or genes.empty? 
#    genes = genes.ensembl.remove(masked_genes)
#    num = genes.length
#    counts[pathway] = num
#  end
#
#  set_info :total_genes, total_genes.remove(masked_genes).length
#  set_info :total_gene_list, total_genes.remove(masked_genes)
#
#  counts
#end


#
#
#dep do |jobname, inputs| job(inputs[:baseline], inputs[:database].to_s, inputs) end
#dep do |jobname, inputs| job(inputs[:mutation_subset] || :relevant_mutations, jobname, inputs) end
#dep :affected_samples_per_pathway
#input :database, :string
#input :mutation_subset, :select, "Mutation subset to use", :relevant_mutations
#input :baseline, :select, "Type of baseline to use", :bases, :select_options => [:pathway_base_counts, :pathway_gene_counts]
#input :permutations, :integer, "Number of permutations in test", 10000
#input :fdr, :boolean, "BH FDR corrections", true
#input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
#input :organism, :string, "Organism code", metadata[:organism]
#task :sample_pathway_enrichment_old => :tsv do |database,mutation_subset,baseline,permutations,fdr,masked_genes,organism|
#  pathway_counts                         = step(baseline).load
#  pathway_counts.unnamed                 = true
#  total_covered                          = step(baseline).info[:total_size] || step(baseline).info[:total_genes]
#  total_pathway_genes_list               = step(baseline).info[:total_gene_list]
#  mutations                              = step(mutation_subset).load
#  affected_samples_per_pathway           = step(:affected_samples_per_pathway).load
#  affected_samples_per_pathway.namespace = organism
#
#  affected_genes = mutations.genes.compact.flatten.uniq
#
#  case database.to_s
#  when 'kegg'
#    database_tsv = KEGG.gene_pathway.tsv :key_field => 'KEGG Pathway ID', :fields => ["KEGG Gene ID"], :type => :flat, :persist => true, :unnamed => false, :merge => true
#  when 'go', 'go_bp'
#    database_tsv = Organism.gene_go_bp(organism).tsv :key_field => "GO ID", :fields => ["Ensembl Gene ID"], :type => :flat, :persist => true, :unnamed => false, :merge => true
#  when 'pfam'
#    database_tsv = Organism.gene_pfam(organism).tsv :key_field => "Pfam Domain", :fields => ["Ensembl Gene ID"], :type => :flat, :persist => true, :unnamed => false, :merge => true
#  end
#
#  covered_genes_per_samples = {}
#  samples = []
#  study.cohort.each do |genotype|
#    samples << genotype.jobname
#    covered_genes_per_samples[genotype.jobname] = genotype.subset(mutations).genes.compact.flatten.subset(total_pathway_genes_list)
#  end
#
#  sample_mutation_tokens = []
#  samples.collect{|sample| study.cohort[sample].subset(mutations).genes.select{|l| not l.nil? and (l & total_pathway_genes_list).any? }.length.times{ sample_mutation_tokens << sample } }
#
#  mutation_genes = Misc.process_to_hash(mutations){|list| list.genes}
#  covered_mutations = mutations.select{|mutation|(mutation_genes[mutation] & total_pathway_genes_list).any? }.length
#
#  pathways = pathway_counts.keys
#
#  pathway_expected_counts = {}
#  pathway_counts.with_monitor :desc => "Pathway gene counts" do
#    pathway_counts.through do |pathway, count|
#      next unless affected_samples_per_pathway.include?(pathway) and affected_samples_per_pathway[pathway].any?
#      ratio = count.to_f / total_covered
#      num_token_list = RSRuby.instance.rbinom(permutations, sample_mutation_tokens.length, ratio)
#      pathway_expected_counts[pathway] = num_token_list.collect{|num_tokens|
#        Misc.sample(sample_mutation_tokens, num_tokens.to_i).uniq.length
#      }
#    end
#  end
#
#  tsv = TSV.setup({}, :key_field => affected_samples_per_pathway.key_field, :fields => ["Sample", "Matches", "Expected", "Ratio", "Pathway total", "p-value", "Ensembl Gene ID"], :namespace => organism, :type => :double)
#  affected_samples_per_pathway.through do |pathway, samples|
#    next unless samples.any?
#    next unless pathway_expected_counts.include? pathway
#    pathway_genes = database_tsv[pathway].ensembl
#    samples = samples.uniq.select{|sample| (covered_genes_per_samples[sample] & pathway_genes).any?}
#    count = samples.length
#    expected = Misc.mean(pathway_expected_counts[pathway]).floor
#    pvalue = pathway_expected_counts[pathway].select{|exp_c| exp_c > count}.length.to_f / permutations
#    tsv[pathway] = [samples.sort, [count], [expected], [count.to_f / expected], [pathway_counts[pathway]], [pvalue], pathway_genes.subset(affected_genes)]
#  end
#
#  FDR.adjust_hash! tsv, 5 if fdr
#
#  set_info :covered_mutations, covered_mutations
#  set_info :total_covered, total_covered
#
#  tsv
#end
#
#
#
#
#dep do |jobname, inputs| job(inputs[:baseline], inputs[:database].to_s, inputs) end
#dep do |jobname, inputs| job(inputs[:mutation_subset] || :relevant_mutations, jobname, inputs) end
#input :database, :string
#input :mutation_subset, :select, "Mutation subset to use", :relevant_mutations
#input :baseline, :select, "Type of baseline to use", :bases, :select_options => [:pathway_base_counts, :pathway_gene_counts]
#input :fdr, :boolean, "BH FDR corrections", true
#input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
#input :organism, :string, "Organism code", metadata[:organism]
#task :mutation_pathway_enrichment_old => :tsv do |database,mutation_subset,baseline,fdr,masked_genes,organism|
#  counts        = step(baseline).load
#  total_covered = step(baseline).info[:total_size] || step(baseline).info[:total_genes]
#  mutations     = step(mutation_subset).load
#
#  affected_genes = mutations.genes.compact.flatten.uniq
#
#  # Get database tsv and native ids
#
#  case database
#  when 'kegg'
#    database_tsv = KEGG.gene_pathway.tsv :key_field => 'KEGG Gene ID', :fields => ["KEGG Pathway ID"], :type => :flat, :persist => true, :unnamed => true, :merge => true
#    affected_genes_db = affected_genes.to_kegg
#    all_db_genes = Gene.setup(database_tsv.keys, "KEGG Gene ID", organism).ensembl.uniq
#  when 'go', 'go_bp'
#    database_tsv = Organism.gene_go_bp(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :persist => true, :unnamed => true, :merge => true
#    affected_genes_db = affected_genes
#    all_db_genes = Gene.setup(database_tsv.keys, "KEGG Gene ID", organism).uniq
#  when 'pfam'
#    database_tsv = Organism.gene_pfam(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["Pfam Domain"], :type => :flat, :persist => true, :unnamed => true, :merge => true
#    affected_genes_db = affected_genes
#    all_db_genes = Gene.setup(database_tsv.keys, "KEGG Gene ID", organism).uniq
#  end
#
#  affected_genes = affected_genes.remove(masked_genes)
#  all_db_genes = all_db_genes.remove(masked_genes)
#
#  # Annotate each pathway with the affected genes that are involved in it
#  
#  affected_genes_per_pathway = {}
#  affected_genes_db.zip(affected_genes).each do |gene_db,gene|
#    next if gene_db.nil?
#    pathways = database_tsv[gene_db]
#    next if pathways.nil?
#    pathways.uniq.each do |pathway|
#      affected_genes_per_pathway[pathway] ||= []
#      affected_genes_per_pathway[pathway] << gene
#    end
#  end
#
#  pvalues = TSV.setup({}, :key_field => database_tsv.fields.first, :fields => ["Matches", "Pathway total", "p-value", "Ensembl Gene ID"], :namespace => organism, :type => :double)
#  mutation_genes = Misc.process_to_hash(mutations){|list| list.genes}
#  covered_mutations = mutations.select{|mutation|(mutation_genes[mutation] & all_db_genes).any? }.length
#
#  affected_genes_per_pathway.each do |pathway, genes|
#    pathway_total = counts[pathway]
#    matches = mutations.select{|mutation| (mutation_genes[mutation] & genes).any? }.length
#    pvalue = RSRuby.instance.binom_test(matches, covered_mutations, pathway_total.to_f / total_covered.to_f, "greater")["p.value"]
#
#    pvalues[pathway] = [[matches], [pathway_total], [pvalue], affected_genes.subset(genes).uniq.sort_by{|g| g.name || g}]
#  end
#
#  FDR.adjust_hash! pvalues, 2 if fdr
#
#  set_info :covered_mutations, covered_mutations
#  set_info :total_covered, total_covered
#
#  pvalues
#end
#
#
#dep do |jobname, inputs| job(:pathway_base_counts, inputs[:database].to_s, inputs) end
#dep do |jobname, inputs| job(inputs[:mutation_subset] || :relevant_mutations, jobname, inputs) end
#dep :affected_genes
#input :database, :string
#input :fdr, :boolean, "BH FDR corrections", true
#input :mutation_subset, :select, "Mutation subset to use", :relevant_mutations
#
##{{{ RATIOS
#
#dep :affected_samples_per_pathway
#dep :affected_genes
#dep do |name, inputs| 
#  database = inputs[:database]
#  if inputs[:type] == :genes
#    job(:pathway_base_counts, database, inputs)
#  else
#    job(:pathway_gene_counts, database, inputs)
#  end
#end
#task :pathway_sample_ratios => :tsv do 
#  num_samples = study.cohort.length
#
#  affected_samples_per_pathway = step(:affected_samples_per_pathway).load
#  affected_genes = step(:affected_genes).load
#
#  ratios = TSV.setup({}, :key_field => sample_pathway_probability.key_field, :fields => ["Num Samples", "Expected", "Ratio", "Ensembl Gene ID"], :namespace => organism)
#
#  pathways.through do |pathway, probability|
#    next unless affected_samples_per_pathway.include?(pathway) and affected_samples_per_pathway[pathway].length > 1
#    affected_samples = (affected_samples_per_pathway[pathway] || []).length
#    ratios[pathway] = [affected_samples, probability * num_samples, affected_samples.to_f / (probability * num_samples), pathway.genes.ensembl.subset(affected_genes)]
#  end
#
#  ratios.namespace = organism
#
#  ratios
#end
#

#input :database, :string
#dep :damaging_mutations
#dep :affected_genes
#task :pathway_mutation_ratios => :tsv do |database|
#  damaging_mutations = step(:damaging_mutations).load
#
#  affected_genes = step(:affected_genes).load
#  affected_genes.organism = organism
#
#  pathways = case database
#             when 'go'
#               affected_genes.go_terms
#             when 'go_bp'
#               affected_genes.go_bp_terms
#             when 'go_cc'
#               affected_genes.go_cc_terms
#             when 'go_mf'
#               affected_genes.go_mf_terms
#             when 'pfam'
#               affected_genes.pfam_domains
#             else
#               affected_genes.send(database + '_pathways')
#             end.compact.flatten.uniq
#
#  key_field = nil
#  pathway_genes = Misc.process_to_hash(pathways) do |pathways|
#    pathways.uniq.collect do |pathway| 
#      case database
#      when 'kegg'
#        KeggPathway.setup(pathway, organism)
#        key_field = "KEGG Pathway ID"
#        Gene.setup(pathway.genes, "KEGG Gene ID", organism).ensembl
#      when 'go', 'go_bp', 'go_mf', 'go_cc'
#        GOTerm.setup(pathway, organism)
#        key_field = "GO ID"
#        Gene.setup(pathway.genes, "Ensembl Gene ID", organism).ensembl
#      when 'pfam'
#        PfamDomain.setup(pathway, organism)
#        key_field = "Pfam Domain"
#        Gene.setup(pathway.genes, "Ensembl Gene ID", organism).ensembl
#      end
#    end
#  end
#
#  pathway_mutation_ratios = TSV.setup({}, :key_field => key_field, 
#    :fields => ["Mutations per MB", "# Mutations", "# Damaging Mut.",  "# Genes", "# Bases", "Ensembl Gene ID"], :type => :double)
#
#
#  pathway_sizes = Misc.process_to_hash(pathways) do |pathways| 
#    pathways.collect{|pathway| Gene.gene_list_exon_bases(pathway_genes[pathway])}
#  end
#
#  pathways_for_mutations = Misc.process_to_hash(study.cohort.flatten){|all_mutations| Gene.setup(study.cohort.collect{|genotype| genotype.genes }.flatten(1), "Ensembl Gene ID", organism).collect{|genes| 
#    genes.nil? ? [] : genes.collect{|gene| 
#      case database
#      when 'go'
#        gene.go_terms
#      when 'go_bp'
#        gene.go_bp_terms
#      when 'go_cc'
#        gene.go_cc_terms
#      when 'go_mf'
#        gene.go_mf_terms
#      when 'pfam'
#        gene.pfam_domains
#      else
#        affected_genes.send(database + '_pathways')
#      end 
#    }.flatten}
#  }
#
#  mutations_in_pathway = Misc.process_to_hash(pathways) do |pathways|
#    pathways.collect do |pathway|
#      GenomicMutation.setup(pathways_for_mutations.select{|mut,pths| pths and pths.include? pathway}.collect{|mut, pths| mut}, "Pathway mutations #{pathway} in #{study}", organism, watson)
#    end
#  end
#
#  pathways.each do |pathway| 
#    pathway_mutations = mutations_in_pathway[pathway]
#    next if pathway_mutations.one?
#    pathway_score = pathway_mutations.length.to_f / pathway_sizes[pathway]
#    genes = pathway_mutations.genes.compact.flatten.subset(affected_genes).subset(pathway_genes[pathway])
#
#    pathway_mutation_ratios[pathway] = [["%.5g" % (pathway_score * 1_000_000)], [pathway_mutations.length], [pathway_mutations.subset(damaging_mutations).length], [pathway_genes[pathway].length], [pathway_sizes[pathway]],  genes]
#  end
#
#  pathway_mutation_ratios.namespace = organism
#
#  pathway_mutation_ratios
#end
#
