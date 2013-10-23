$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '../..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'test/unit'
require 'rbbt/entity/study'
require 'rbbt/entity/study/genotypes'

class TestStudy < Test::Unit::TestCase
  def setup
    Workflow.require_workflow "Genomics"
    require 'rbbt/entity/genomic_mutation'
  end

  def test_knowledge_base
    study  = Study.setup("AML")
    study.dir = Path.setup("/home/mvazquezg/git/apps/ICGCScout/studies/Acute_Myeloid_Leukemia-TCGA-US/")

    db = nil
    db = study.knowledge_base.get_database(:sample_genes, :persist => false)
    assert db.length > 1
  end
end
 
