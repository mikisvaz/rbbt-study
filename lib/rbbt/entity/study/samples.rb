module Sample
  extend Entity

  annotation :study
end

module Study

  def sample_info
    @sample_info ||= dir.samples.tsv
  end

  def samples
    if @samples.nil?
      @samples = sample_info.keys
      Sample.setup(@samples, self)
      @samples.study = self
    end
    @samples
  end

  def has_cnv?
    study.has_cnv? and study.cnv_cohort.include? self
  end
  
  def has_mutations?
    study.cohort and study.cohort.include? self
  end
end
