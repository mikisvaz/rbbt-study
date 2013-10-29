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
      if sample_info.nil?
        @samples = self.cohort.collect{|g| g.jobname }
      else
        @samples = sample_info.keys
      end
      Sample.setup(@samples, self)
      @samples.study = self
    end
    @samples
  end

  def match_samples(list)
    if donor_id_field = (sample_info = self.sample_info).fields.select{|f| f =~ /donor\s+id/i}.first
      list_donors = sample_info.select(list).slice(donor_id_field).values.compact.flatten
      list_donor_samples = sample_info.select(list_donors).keys
      list = list_donor_samples.annotate((list + list_donor_samples).uniq)
    end
    list
  end
end
