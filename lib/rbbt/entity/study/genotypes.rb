require 'rbbt/entity/genotype'

require 'rbbt/entity/study/genotypes/mutations'
require 'rbbt/entity/study/genotypes/genes'
require 'rbbt/entity/study/genotypes/enrichment'

module StudyWorkflow
  helper :organism do
    study.metadata[:organism]
  end
end

module Study
  def has_genotypes?
    dir.genotypes.exists?
  end

  attr_accessor :watson
  def watson
    @watson  = metadata[:watson] if @watson.nil?
    @watson
  end

  def genotype_files
    dir.genotypes.glob("*")
  end

  def cohort
    @cohort ||= genotype_files.collect do |f| 
      name = File.basename(f)
      genomic_mutations = Open.read(f).split("\n").sort
      GenomicMutation.setup(genomic_mutations, name, organism, watson)
    end.tap{|cohort| cohort.extend Genotype::Cohort}
  end
end
