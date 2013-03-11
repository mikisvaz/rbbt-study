require 'rbbt'
require 'rbbt/util/misc'

require 'rbbt/entity'
require 'rbbt/resource'
require 'rbbt/workflow'

require 'rbbt/entity/study/samples'
require 'rbbt/expression/matrix'

module StudyWorkflow
  extend Workflow

  helper :study do 
    @study
  end

  helper :dir do
    study.dir
  end

  helper :organism do
    study.metadata[:organism]
  end
end

module Study
  extend Entity
  extend Resource

  attr_accessor :workflow

  def job(task, *args)
    name, inputs = args
    if inputs.nil? and Hash === name
      inputs = name
      name = nil
    end
    name = self if name.nil? or name == :self or name == "self"
    step = workflow.job(task, name, {:organism => metadata[:organism], :watson => metadata[:watson]}.merge(inputs || {}))
    step.instance_variable_set(:@study, self)
    step
  end

  def workflow(&block)
    if block_given?
      @workflow.instance_eval &block
    else
      @workflow
    end
  end

  def self.annotation_repo
    @annotation_repo ||= Rbbt.var.cache.annotation_repo.find
  end

  def self.extended(base)
    setup_file = File.join(base.dir, 'setup.rb')
    base.workflow = StudyWorkflow.clone
    if File.exists? setup_file
      base.instance_eval Open.read(setup_file), setup_file
    end
  end

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
    if @dir.nil?
      @dir = Path.setup(File.join(Study.study_dir, self))
      @dir.resource = Study
    end
    @dir
  end


  def metadata
    @metadata ||= (dir["metadata.yaml"].yaml.extend IndiferentHash)
  end

  def users
    @users ||= metadata[:users] || []
  end

  #{{{ Attributes
  attr_accessor :organism
  def organism
    @organism ||= metadata["organism"]
  end

  def matrix_file(name)
    dir.matrices[name.to_s].find
  end

  def matrices
    dir.matrices.glob('*').collect{|f| f.basename}
  end

  def matrix(type, format = "Ensembl Gene ID", organism = nil)
    organism = self.metadata[:organism] if organism.nil?
    raise "No matrices defined for study #{ self }" unless defined? matrices.empty?
    raise "No type specified" if type.nil?
    type = type.to_s
    raise "No matrix #{ type } defined for study #{ self }" unless matrices.include? type
    data = dir.matrices[type].data.find if dir.matrices[type].data.exists?
    identifiers = dir.matrices[type].identifiers.find if dir.matrices[type].identifiers.exists?
    samples = dir.matrices[type].samples.find if dir.matrices[type].samples.exists?
    samples = dir.samples.find if samples.nil? and dir.samples.exist?
    Matrix.new(data, identifiers, samples, format, organism)
  end

end

if __FILE__ == $0
  require 'rbbt/entity/study/genotypes'
  require 'rbbt/entity/study/cnv'

  Workflow.require_workflow "Expression"

  module Sample
    persist :gained_genes, :annotations, :annotation_repo => "var/cache/annotation_repo"
  end

  YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE and YAML::ENGINE.respond_to? :yamler

  Workflow.require_workflow :enrichment.to_s

  Sample.persist :gained_genes, :annotations, :annotation_repo => Study.annotation_repo

  s = Study.setup("bladder-preal")

  ddd Path === s.samples.first.dir
  exit

  puts s.job(:oncodriveFM).run
  exit

  puts s.job(:salute, {}).run

  s = Study.setup("bladder-preal")
  puts s.job(:salute, {}).run

  exit
  Open.write('/home/mvazquezg/tmp/muts2', s.damaging_mutations * "\n")
  exit
  ddd s.damaging_mutations.damaged_genes.compact.flatten.uniq.length
  ddd s.damaged_genes.compact.flatten.uniq.length
  exit
  s = Study.setup("Ovary-TCGA")
  class << s
    GENE_HASH = {:format => "Ensembl Gene ID", :organism => "Hsa/may2009"}
    def gene_setup(g)
      g = g.dup
      g.extend Gene
      Gene.setup_hash(g, GENE_HASH)
    end
  end

  counts = {}
  s.samples.each do |sample|
    next unless sample.has_cnvs?
    puts sample

    genes = nil
    genes = sample.gained_genes.clean_annotations
    genes.each do |gene|
      counts[gene] ||= 0
      counts[gene] += 1 
    end
  end

  sig = Signature.setup(counts)

  #Misc.profile(:min_percent => 0.1) do
  #  puts counts.select{|k,c| c > 4 }.sort_by{|k,c| c}.collect{|k,v| k = s.gene_setup(k); [k, v] * ": "} * "\n"
  #end
  #Misc.profile(:min_percent => 0.1) do
  #  puts counts.select{|k,c| c > 4 }.sort_by{|k,c| c}.collect{|k,v| k = s.gene_setup(k); [k.name, v] * ": "} * "\n"
  #end
   
end
