require 'rbbt'
require 'rbbt/util/misc'

require 'rbbt/entity'
require 'rbbt/resource'
require 'rbbt/workflow'

require 'rbbt/entity/study/samples'
require 'rbbt/expression/matrix'

module StudyWorkflow
  extend Workflow

  def self.workdir
    @workdir ||= Rbbt.var.jobs["Study"].find
  end

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
  include LocalPersist


  attr_accessor :workflow, :dir

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
    base.local_persist_dir = base.dir.var.cache.persistence.find
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
