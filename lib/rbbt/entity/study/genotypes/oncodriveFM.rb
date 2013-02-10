require 'rbbt/mutation/oncodriveFM'
module StudyWorkflow
  task :oncodriveFM => :tsv do 
    tsv, input, config = OncodriveFM.process_cohort(study.cohort, true)
    Open.write(file("input"), input)
    Open.write(file("config"), config)
    tsv.namespace = study.metadata[:organism]
    tsv
  end
end
