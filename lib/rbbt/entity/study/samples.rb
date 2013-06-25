module Sample
  extend Entity

  annotation :study

  self.format = ["Sample ID"]

  def dir
    return nil if study.nil?
    return study.dir if study.respond_to? :dir
    begin
      Study.setup(study).dir
    rescue
      Log.warn "Error accessing sample dir from study: #{$!.message}"
      nil
    end
  end

  def organism
    return nil if study.nil?
    study.organism
  end
end

module Study

  def sample_info
    return nil unless dir.samples.exists?
    @sample_info ||= dir.samples.tsv.tap{|tsv| tsv.entity_options = {:study => self }}
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