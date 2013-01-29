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
end
