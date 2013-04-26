module Sample
  property :has_genotype? => :array2single do
    study.cohort.values_at(*self).collect{|g| not g.nil?}
  end

  property :mutations do
    Study.setup(study)
    study.cohort[self]
  end

  property :affected_genes do
    mutations.affected_genes.compact.flatten.uniq
  end
end


