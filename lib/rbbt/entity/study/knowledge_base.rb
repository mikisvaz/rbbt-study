module Study

  class << self
    attr_accessor :knowledge_base, :study_registry
    def knowledge_base
      @knowledge_base ||= KnowledgeBase.new Rbbt.var.knowledge_base.Study 
    end

    def study_registry
      @study_registry ||= {}
    end
  end

  attr_accessor :knowledge_base

  def knowledge_base
    @knowledge_base ||= begin 
                          kb = KnowledgeBase.new(self.dir.var.knowledge_base, self.organism)
                          kb.format["Gene"] = "Ensembl Gene ID"
                          kb.entity_options["Sample"] = {"Study" => self}
                          Study.study_registry.each do |database, file|
                            Log.debug("Inheriting #{ database } from registry: #{Misc.fingerprint file}")
                            if Proc === file
                              study = self
                              block = Proc.new{ file.call(self, database) }
                              block.define_singleton_method(:filename) do [database, study] * "@" end
                              kb.register database, nil, {}, &block 
                            else
                              kb.register database, file
                            end
                          end
                          kb
                        end
  end
end

