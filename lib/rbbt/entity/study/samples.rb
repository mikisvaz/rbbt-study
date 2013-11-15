module Study
end

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

  def study
    @study ||= begin
                 study = info[:study] 
                 if study.nil?
                   study = Study.identify_study(self)
                   self.study = study
                 end
                 study
               end
  end

end

module Study

  def sample_info
    return nil unless dir.samples.exists?
    @sample_info ||= dir.samples.tsv.tap{|tsv| tsv.entity_options = {:study => self }}
  end

  def samples
    @samples ||= begin
                   samples = local_persist("Sample", :array) do
                     if sample_info.nil?
                       self.cohort.collect{|g| g.jobname }
                     else
                       sample_info.keys
                     end
                   end
                   Sample.setup(samples, :study => self)
                   samples.study = self
                   samples
                 end
  end

  def match_samples(list)
    if donor_id_field = (sample_info = self.sample_info).fields.select{|f| f =~ /donor\s+id/i}.first
      list_donors = sample_info.select(list).slice(donor_id_field).values.compact.flatten
      list_donor_samples = sample_info.select(list_donors).keys
      list = list_donor_samples.annotate((list + list_donor_samples).uniq)
    end
    list
  end

  def self.identify_study(samples)
    samples = Array === samples ? samples.flatten : [samples]

    studies = Study.studies.select{|study| Study.setup(study); (study.samples & samples).any? }
    return nil if studies.length != 1

    studies.first
  end
end
