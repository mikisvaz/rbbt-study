module Sample
  property :has_genotype? => :array2single do
    study.cohort.values_at(*self).collect{|g| not g.nil?}
  end

  property :mutations do
    Study.setup(study)
    study.cohort[self]
  end

  property :relevant_mutations do
    mutations.select_by(:relevant?)
  end

  property :damaging_mutations do |*args|
    mutations.select_by(:damaging?, *args)
  end

  property :affected_genes do
    mutations.affected_genes.compact.flatten.uniq
  end

  property :damaged_genes do |*args|
    mutations.damaged_genes(*args).compact.flatten.uniq
  end
end


