require 'rbbt/entity/cnv'

module StudyWorkflow
  helper :organism do
    study.metadata[:organism]
  end
end

module Study
  def has_cnv?
    dir.cnv.exists?
  end

  def cnv_files
    dir.cnv.find.glob("*")
  end

  def cnv_cohort
    if @cnv_cohort.nil?
      @cnv_cohort = {}
      cnv_files.each do |f| 
        sample = File.basename(f)
        Sample.setup(sample, self)
        cnvs = Open.read(f).split("\n").sort
        CNV.setup(cnvs , sample, organism)
        @cnv_cohort[sample] =  cnvs
      end
    end
    @cnv_cohort
  end
end

module Sample
  property :cnvs => :array2single do
    study.cnv_cohort
  end

  property :has_cnvs? => :array2single do
    study.cnv_cohort.values_at(*self).collect{|cnvs| not cnvs.nil?}
  end
  
  property :gained_cnvs => :single do
    cnvs.select_by(:gain?)
  end
 
  property :lost_cnvs => :single do
    cnvs.select_by(:loss?)
  end

  property :gained_genes => :single do
    gained_cnvs.genes.flatten.uniq
  end

  property :lost_genes => :single do
    lost_cnvs.genes.flatten.uniq
  end

end

module Study
  property :recurrently_lost_genes => :single do |threshold|
    counts = {}
    self.samples.each do |sample|
      next unless sample.has_cnvs?
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
      next unless sample.has_cnvs?
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
end
