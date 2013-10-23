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
    tsv = TSV.setup({}, :key_field => "Sample", :fields => ["Ensembl Gene ID", "Genomic Mutation", "Affected isoform", "Damaged isoform", "Exon Junction"], :type => :double, :namespace => study.organism)
    gene_mutations = study.knowledge_base.get_database(:mutation_genes, :source => "Ensembl Gene ID")
    sample_mutations = study.knowledge_base.get_database(:sample_mutations, :source => "Sample")

    require 'progress-monitor'
    Progress.monitor "Mon", :stack_depth => 1
    study.samples.select_by(:has_genotype?)[0..3].each do |sample|
      values = sample.affected_genes.collect do |gene|
        mutations = gene_mutations[gene].subset(sample_mutations[sample] || [])
        if mutations.any?
          junction = mutations.select_by(:in_exon_junction?).any?

          mis = Annotated.flatten mutations.mutated_isoforms.compact

          affected = (mis.any? and mis.select_by(:consequence){|c| ! %w(UTR SYNONYMOUS).include? c}.any?) 
          damaged = (mis.any? and mis.select_by(:damaged?).any?) 

          [gene, mutations * ";;", affected, damaged, junction]
        else
          [gene, "", false, false, false]
        end
      end

      tsv[sample] = Misc.zip_fields values
    end
    tsv
  }

end
