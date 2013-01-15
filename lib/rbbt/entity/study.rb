require 'rbbt'
require 'rbbt/util/misc'

require 'rbbt/entity'
require 'rbbt/resource'

module Study
  extend Entity

  def self.study_dir
    @study_dir ||= begin
                     case
                     when (not defined?(Rbbt))
                       File.join(ENV["HOME"], '.studies')
                     when Rbbt.etc.study_dir.exists?
                       Rbbt.etc.study_dir.read.chomp
                     else
                       Rbbt.studies.find
                     end
                   end
  end

  def self.studies
    Dir.glob(File.join(Path === study_dir ? study_dir.find : study_dir, '*')).
      select{|f| File.directory? f}.sort.collect{|s| Study.setup(File.basename(s))}
  end

  def dir
    Path.setup(File.join(Study.study_dir, self))
  end

  def metadata
    dir["metadata.yaml"].yaml.extend IndiferentHash
  end

  #{{{ Attributes
  attr_accessor :organism
  def organism
    @organism ||= metadata["organism"]
  end
  
end
if __FILE__ == $0
  require 'rbbt/entity/study/genotypes'

  YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE and YAML::ENGINE.respond_to? :yamler

  class G
    attr_accessor :code, :format, :organism
    def initialize code, format, organism
      @code, @format, @organism = code, format, organism
    end
  end

  Workflow.require_workflow :enrichment.to_s
  Study.persist :recurrent_genes, :annotations
  s = Study.setup("bladder-preal")

  recurrent = s.recurrent_genes
  tsv = Enrichment.job(:enrichment, nil, :list => recurrent, :database => :nature).clean.run
  ddd tsv.keys.annotations
  ddd tsv.keys.info


  exit
  Misc.benchmark do
    10_000.times do
      G.new("SF3B1", "Associated Gene Name", "Hsa/jun2011")
    end
  end

  Misc.benchmark do
    10_000.times do
      Gene.setup("SF3B1", :format => "Associated Gene Name", :organism => "Hsa/jun2011")
    end
  end

  exit

  Misc.profile(:min_percent => 1) do
    10_000.times do
      Gene.setup("SF3B1", :format => "Associated Gene Name", :organism => "Hsa/jun2011")
      #Gene.setup("SF3B1", "Associated Gene Name", "Hsa/jun2011")
    end
  end
end
