module Sample
  property :methylation => :array2single do
    study.methylation_cohort
  end

  property :has_methylation? => :array2single do
    study.methylation_cohort.values_at(*self).collect{|methylation| not methylation.nil?}
  end
  
  property :methylated => :single do
    return [] if methylation.empty?
    methylation.select_by(:methylated?)
  end
 
  property :unmethylated => :single do
    return [] if methylation.empty?
    methylation.select_by(:unmethylated?)
  end

  property :methylated_genes => :single do
    return [] if methylated.empty?
    Gene.setup(methylated.genes.flatten.uniq, "Ensembl Gene ID", organism)
  end

  property :unmethylated_genes => :single do
    return [] if unmethylated.empty?
    Gene.setup(unmethylated.genes.flatten.uniq, "Ensembl Gene ID", organism)
  end
end


