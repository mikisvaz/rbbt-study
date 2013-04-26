require 'rbbt/entity/methylation'

require 'rbbt/entity/study/methylation/samples'

module StudyWorkflow
  helper :organism do
    study.metadata[:organism]
  end
end

module Study
  def has_methylation?
    dir.methylation.exists?
  end

  def methylation_files
    dir.methylation.find.glob("*")
  end

  def methylation_cohort
    if @methylation_cohort.nil?
      @methylation_cohort = {}
      methylation_files.each do |f| 
        sample = File.basename(f)
        Sample.setup(sample, self)
        methylations = Open.read(f).split("\n").sort
        Methylation.setup(methylations, organism)
        @methylation_cohort[sample] =  methylations
      end
    end
    @methylation_cohort
  end
end

module Study
  property :recurrently_lost_genes => :single do |threshold|
    counts = {}
    self.samples.each do |sample|
      next unless sample.has_methylation?
      puts sample

      genes = nil
      genes = sample.lost_genes.clean_annotations
      genes.each do |gene|
        counts[gene] ||= 0
        counts[gene] += 1 
      end
    end

    recurrent = counts.select{|k,c| c >= threshold }.collect{|k,v| k }
    Gene.setup(recurrent, "Ensembl Gene ID", organism)
  end

  property :recurrently_gained_genes => :single do |threshold|
    counts = {}
    self.samples.each do |sample|
      next unless sample.has_methylation?
      puts sample

      genes = nil
      genes = sample.gained_genes.clean_annotations
      genes.each do |gene|
        counts[gene] ||= 0
        counts[gene] += 1 
      end
    end

    recurrent = counts.select{|k,c| c >= threshold }.collect{|k,v| k }
    Gene.setup(recurrent, "Ensembl Gene ID", organism)
  end

  property :gene_sample_methylation_matrix => :single do
    tsv = TSV.setup({}, :key_field => "Ensembl Gene ID", :namespace => organism, :type => :list)
    samples = []
    i = 0
    num_samples = cohort.length
    methylation_cohort.each do |sample,methylation|
      methylation.genes.compact.flatten.uniq.each do |gene|
        tsv[gene] ||= ["FALSE"] * num_samples
        tsv[gene][i] = "TRUE"
      end
      samples << sample
      i += 1
    end

    tsv.fields = samples

    tsv
  end
end
