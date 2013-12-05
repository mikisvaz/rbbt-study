require 'rbbt/knowledge_base'
require 'rbbt/workflow'
Workflow.require_workflow "Genomics"
require 'rbbt/entity/study'
require 'rbbt/entity/study/cnv'
require 'rbbt/entity/gene'
require 'rbbt/entity/genomic_mutation'

module Study

  self.study_registry[:sample_cnv_genes] = Proc.new{|study,database|
    tsv = TSV.setup({}, :key_field => "Sample", :fields => ["Ensembl Gene ID", "CNV Variation"], :type => :double, :namespace => study.organism)

    all_cnvs = CNV.setup(study.cnv_cohort.values.flatten, study.organism)
    cnv2genes = Misc.process_to_hash(all_cnvs){|cnvs| cnvs.genes }

    study.cnv_cohort.each do |sample,cnvs|
      Log.info sample
      genes = []
      variations = []
      cnvs.variation.zip(cnv2genes.chunked_values_at(cnvs)).each_with_index do |p,i|
        variation, genes = p
        Annotated.purge(genes).each{|gene| genes << gene; variations << variation }
      end
      tsv[sample] = [genes.to_a, variations.to_a]
    end

    tsv
  }

end

if __FILE__ == $0
  Workflow.require_workflow "ICGC"
  Study.study_dir = ICGC.root
  s = Study.setup("Glioblastoma_Multiforme-TCGA-US")
  puts s.knowledge_base.get_database(:sample_cnv_genes).value_peek

end
