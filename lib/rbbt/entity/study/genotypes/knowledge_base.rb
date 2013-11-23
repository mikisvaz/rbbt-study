require 'rbbt/workflow'
Workflow.require_workflow "Genomics"
require 'rbbt/entity/gene'
require 'rbbt/entity/genomic_mutation'

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

    sample_mutations = study.knowledge_base.get_database(:sample_mutations, :source => "Sample")
    all_mutations = study.all_mutations
    mutations2mutated_isoforms = Misc.process_to_hash(all_mutations){|mutations| mutations.any? ? mutations.mutated_isoforms : [] }
    mutations2exon_junction = Misc.process_to_hash(all_mutations){|mutations| mutations.any? ? mutations.in_exon_junction? : [] }
    mi2damaged = Misc.process_to_hash(MutatedIsoform.setup(mutations2mutated_isoforms.values.flatten.compact.uniq, study.organism)){|mis| mis.any? ? mis.damaged? : [] }
    #mi2damaged = Misc.process_to_hash(MutatedIsoform.setup(mutations2mutated_isoforms.values.flatten.compact.uniq, study.organism)){|mis| [false] * mis.length }
    mi2consequence = Misc.process_to_hash(MutatedIsoform.setup(mutations2mutated_isoforms.values.flatten.compact.uniq, study.organism)){|mis| mis.any? ? mis.consequence : [] }

    gene_mutations = study.knowledge_base.get_database(:mutation_genes, :source => "Ensembl Gene ID")
    gene_mutations.unnamed = true
    gene_mutations.entity_options["Genomic Mutation"] = {:watson => study.watson, :organism => study.organism}
    study.samples.select_by(:has_genotype?).each do |sample|
      values = sample.affected_genes.collect do |gene|
        mutations = gene_mutations[gene] & (sample_mutations[sample] || [])

        if mutations.any?
          GenomicMutation.setup(mutations, "Mutations in #{ sample } over #{ gene }", study.organism, study.watson)
          junction = mutations.select{|mutation| mutations2exon_junction[mutation] }.any?

          mis = Annotated.flatten mutations2mutated_isoforms.values_at(*mutations).compact

          affected = (mis.any? and mis.select{|mi| c = mi2consequence[mi]; ! %w(UTR SYNONYMOUS).include? c}.any?) 
          damaged = (mis.any? and mis.select{|mi| mi2damaged[mi]  }.any?) 

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
