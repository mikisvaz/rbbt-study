require 'rbbt'
require 'rbbt/util/misc'

require 'rbbt/entity'
require 'rbbt/resource'
require 'rbbt/workflow'

Workflow.require_workflow "Genomics"

require 'rbbt/entity/study'
require 'rbbt/entity/study/knowledge_base'
require 'rbbt/entity/study/samples'
require 'rbbt/expression/matrix'

module StudyWorkflow
  extend Workflow

  class << self
    attr_accessor :study
  end

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

  def self.job(*args)
    super(*args).tap{|s| s.instance_variable_set("@study", @study) }
  end
end

module Study
  extend Entity
  extend Resource
  include LocalPersist

  class << self
    attr_accessor :study_dir
    def study_dir
      @study_dir ||= begin
                       case
                       when (not defined?(Rbbt))
                         Path.setup(File.join(ENV["HOME"], '.studies'))
                       when Rbbt.etc.study_dir.exists?
                         Path.setup(Rbbt.etc.study_dir.read.chomp)
                       else
                         Rbbt.studies.find
                       end
                     end
    end
  end

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
    base.workflow = StudyWorkflow.clone
    base.workflow.study = base

    if File.exists?(setup_file = File.join(base.dir, 'setup.rb'))
      base.instance_eval Open.read(setup_file), setup_file
    end

    base.local_persist_dir = Rbbt.var.cache.studies[base].persistence.find

    base
  end

  def self.studies
    Dir.glob(File.join(Path === study_dir ? study_dir.find : study_dir, '*')).
      select{|f| File.directory? f}.sort.collect{|s| Study.setup(File.basename(s))}
  end

  def self.studies
    case study_dir
    when nil
      []
    when Path 
      study_dir.find_all.collect do |study_path| 
        study_path.glob('*').select{|f| f.directory? }
      end.flatten.collect{|f| self.annotate f} 
    else
      Dir.glob(File.join(study_dir, "*"))
    end.sort.collect do |dir| 
      study = Study.setup(File.basename(dir))
      study.dir = study_dir.annotate(dir)
      study
    end
  end

  def dir
    @dir ||= if Path === Study.study_dir
               Study.study_dir[self] 
             else
               Path.setup(File.join(Study.study_dir.dup, self), nil, Study)
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
    dir.matrices[name.to_s].produce.find
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
    if dir.matrices[type].identifiers.exists?
      identifiers = dir.matrices[type].identifiers.find 
    else
      identifiers = Organism.identifiers(organism).find
    end
    samples = dir.matrices[type].samples.find if dir.matrices[type].samples.exists?
    samples = dir.samples.find if samples.nil? and dir.samples.exist?
    Matrix.new(data, identifiers, samples, format, organism)
  end
end
