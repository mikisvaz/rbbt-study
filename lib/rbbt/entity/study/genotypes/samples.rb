module Sample

  property :mutations do
    Study.setup(study)
    study.cohort[self]
  end

  property :affected_genes do
    mutations.affected_genes.compact.flatten.uniq
  end

end


