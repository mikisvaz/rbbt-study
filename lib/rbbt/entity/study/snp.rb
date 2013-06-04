require 'rbbt/entity/snp'

#require 'rbbt/entity/study/snp/samples'

module StudyWorkflow
end

module Study
  def has_snp?
    dir.snp.exists?
  end

  def snp_files
    @snp_files ||= dir.snp.find.glob("*")
  end

  def snp_cohort
    if @snp_cohort.nil?
      @snp_cohort = {}
      snp_files.each do |f| 
        sample = File.basename(f)
        Sample.setup(sample, self)
        snps = Open.read(f).split("\n").sort
        SNP.setup(snps)
        @snp_cohort[sample] =  snps
      end
    end
    @snp_cohort
  end
end

module Study

  def snp_index
    local_persist_tsv("SNP2Samples", "SNP2Samples", {}, :persist => true, :serializer => :clean) do |data|

      require 'progress-monitor'
      Progress.monitor "SNP files", :stack_depth => 0
      snp_files.each do |file|
        file = file.to_s
        sample = File.basename file
        File.open(file.to_s) do |f|
          while line = f.gets
            snp = line.strip
            snp, allele = snp.split ":"
            snp_str = data[snp]

            if snp_str.nil?
              snp_str = ""
            else
              snp_str += "\t"
            end

            if allele
              snp_str << sample << ":" << allele
            else
              snp_str << sample
            end
            data[snp] = snp_str
          end
        end
      end

      TSV.setup data
      data.key_field = "RS ID"
      data.fields = ["Sample"]
      data.type = :flat
      data.serializer = :list
      data
    end
  end

  property :samples_with_snp => :single2array do |snp|
    Sample.setup((snp_index[snp] || []).collect{|s| s.split(":").first}, self)
  end

  property :samples_with_homozygous_snp => :single2array do |snp|
    Sample.setup((snp_index[snp] || []).collect{|s| s.split(":")}.select{|s,g| g == "2"}.collect{|s,g| s}, self)
  end

  property :samples_with_heterozygous_snp => :single2array do |snp|
    Sample.setup((snp_index[snp] || []).collect{|s| s.split(":")}.select{|s,g| g == "1"}.collect{|s,g| s}, self)
  end



end
