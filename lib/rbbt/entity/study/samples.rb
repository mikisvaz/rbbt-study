# NON UNIQ
dep :relevant_mutations
input :only_relevant, :boolean, "Consider only relevant mutations", true
task :affected_samples_per_gene => :tsv do |only_relevant|
  relevant_mutations = step(:relevant_mutations).load

  tsv = TSV.setup({}, :key_field => "Ensembl Gene ID", :fields => ["Sample"], :type => :flat)
  study.cohort.each do |genotype|
    mutations = only_relevant ? genotype.subset(relevant_mutations) : genotype
    (mutations.affected_genes || []).compact.flatten.each do |gene|
      tsv[gene] ||= []
      if defined? Entity and defined? Sample
        tsv[gene] << Sample.setup(genotype.jobname, study)
      else
        tsv[gene] << genotype.jobname
      end
    end
  end

  tsv.namespace = organism

  tsv
end

dep :affected_samples_per_gene
returns "Ensembl Gene ID"
task :genes_affecting_several_samples => :annotations do
  affected_samples_per_gene = step(:affected_samples_per_gene).load

  genes = affected_samples_per_gene.select{|gene, samples| samples.uniq.length > 1}.collect{|gene, samples| gene}

  Gene.setup(genes, "Ensembl Gene ID", organism)
end



dep :affected_samples_per_gene
task :mutated_genes_per_sample => :tsv do
  tsv = TSV.setup({}, :key_field => "Sample", :fields => ["Ensembl Gene ID"], :type => :flat)

  step(:affected_samples_per_gene).load.each do |gene, samples|
    samples.uniq.each do |sample|
      tsv[sample] ||= []
      tsv[sample] << gene
    end
  end

  tsv.namespace = organism

  tsv
end

# NON UNIQ
dep :affected_samples_per_gene
input :database, :string
input :masked_genes, :array, "Ensembl Gene ID list of genes to mask", []
task :affected_samples_per_pathway => :tsv do |database, masked_genes|
  affected_samples_per_gene = step(:affected_samples_per_gene).load

    case database.to_s
    when 'kegg'
      database_tsv = KEGG.gene_pathway.tsv :key_field => 'KEGG Gene ID', :fields => ["KEGG Pathway ID"], :type => :flat, :persist => true, :unnamed => true, :merge => true
      all_db_genes = Gene.setup(database_tsv.keys, "KEGG Gene ID", organism).uniq
    when 'go'
      database_tsv = Organism.gene_go(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :persist => true, :unnamed => true, :merge => true
      all_db_genes = Gene.setup(database_tsv.keys, "Ensembl Gene ID", organism).uniq
    when 'go_mf'
      database_tsv = Organism.gene_go_bp(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :persist => true, :unnamed => true, :merge => true
      all_db_genes = Gene.setup(database_tsv.keys, "Ensembl Gene ID", organism).uniq
    when 'go_mf'
      database_tsv = Organism.gene_go_mf(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :persist => true, :unnamed => true, :merge => true
      all_db_genes = Gene.setup(database_tsv.keys, "Ensembl Gene ID", organism).uniq
    when 'go_cc'
      database_tsv = Organism.gene_go_cc(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["GO ID"], :type => :flat, :persist => true, :unnamed => true, :merge => true
      all_db_genes = Gene.setup(database_tsv.keys, "Ensembl Gene ID", organism).uniq
    when 'pfam'
      database_tsv = Organism.gene_pfam(organism).tsv :key_field => "Ensembl Gene ID", :fields => ["Pfam Domain"], :type => :flat, :persist => true, :unnamed => true, :merge => true
      all_db_genes = Gene.setup(database_tsv.keys, "Ensembl Gene ID", organism).uniq
    when 'reactome'
      database_tsv = NCI.reactome_pathways.tsv :key_field => "UniProt/SwissProt Accession", :fields => ["NCI Reactome Pathway ID"], :persist => true, :merge => true, :type => :flat, :unnamed => true
      all_db_genes = Gene.setup(database_tsv.keys, "UniProt/SwissProt Accession", organism).uniq
    when 'nature'
      database_tsv = NCI.nature_pathways.tsv :key_field => "UniProt/SwissProt Accession", :fields => ["NCI Nature Pathway ID"], :persist => true, :merge => true, :type => :flat, :unnamed => true
      all_db_genes = Gene.setup(database_tsv.keys, "UniProt/SwissProt Accession", organism).uniq
    when 'biocarta'
      database_tsv = NCI.biocarta_pathways.tsv :key_field => "Entrez Gene ID", :fields => ["NCI BioCarta Pathway ID"], :persist => true, :merge => true, :type => :flat, :unnamed => true
      all_db_genes = Gene.setup(database_tsv.keys, "Entrez Gene ID", organism).uniq
    end

  tsv = database_tsv.reorder database_tsv.fields.first, [database_tsv.key_field]
  affected_samples_per_pathway = TSV.setup({}, :key_field => tsv.key_field, :fields => ["Sample"], :type => :flat)

  tsv.through do |pathway, genes|
    genes = genes.ensembl.remove(masked_genes)
    samples = affected_samples_per_gene.values_at(*genes.ensembl).compact.flatten
    affected_samples_per_pathway[pathway] = samples
  end

  affected_samples_per_pathway.entity_options = {:study => study.clean_annotations}
  affected_samples_per_pathway
end


#dep :affected_samples_per_pathway
#input :use_names, :boolean, "Use names instead of pathway ids", false
#task :sample_pathway_features do |use_names|
#  affected_samples_per_pathway = step(:affected_samples_per_pathway).load
#  samples = Sample.setup(affected_samples_per_pathway.values.compact.flatten.uniq.sort, entity)
#  pathways = affected_samples_per_pathway.keys.sort
#
#  tsv = TSV.setup({}, :key_field => "Sample", :fields => (use_names ? pathways.name : pathways), :type => :list, :cast => :to_i)
#
#  samples.each do |sample|
#    features = pathways.collect{|pathway|
#      affected_samples_per_pathway[pathway].include?(sample) ? 1 : 0
#    }
#    tsv[sample] = features
#  end
#  
#  tsv
#end
