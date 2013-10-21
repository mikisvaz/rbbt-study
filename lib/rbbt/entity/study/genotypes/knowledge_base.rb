module Study

  self.study_registry[:mutation_genes] = Proc.new{|study,database|
    tsv = TSV.setup({}, :key_field => "Genomic Mutation", :fields => ["Ensembl Gene ID"], :type => :flat, :namespace => study.organism)
    study.cohort.metagenotype.uniq.each do |mutation|
      tsv[mutation] = mutation.genes
    end
    tsv
  }

  self.study_registry[:sample_mutations] = Proc.new{|study,database|
    tsv = TSV.setup({}, :key_field => "Sample", :fields => ["Genomic Mutation"], :type => :flat, :namespace => study.organism)
    study.samples.select_by(:has_genotype?).each do |sample|
      tsv[sample] = sample.mutations
    end
    tsv
  }

  self.study_registry[:sample_genes] = Proc.new{|study,database|
    tsv = TSV.setup({}, :key_field => "Sample", :fields => ["Ensembl Gene ID"], :type => :flat, :namespace => study.organism)
    study.samples.select_by(:has_genotype?).each do |sample|
      tsv[sample] = sample.affected_genes
    end
    tsv
  }

  self.study_registry[:sample_genes2] = Proc.new{|study,database|
    tsv = TSV.setup({}, :key_field => "Sample", :fields => ["Ensembl Gene ID", "Genomic Mutation"], :type => :double, :namespace => study.organism)
    kb = study.knowledge_base.get_database(:mutation_genes, :source => "Ensembl Gene ID")
    study.samples.select_by(:has_genotype?).each do |sample|
      values = sample.affected_genes.collect do |gene|
        [gene, kb[gene] * ";;"]
      end
      tsv[sample] = Misc.zip_fields values
    end
    tsv
  }

end
