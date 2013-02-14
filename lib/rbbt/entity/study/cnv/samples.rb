module Sample
  property :cnvs => :array2single do
    study.cnv_cohort
  end

  property :has_cnvs? => :array2single do
    study.cnv_cohort.values_at(*self).collect{|cnvs| not cnvs.nil?}
  end
  
  property :gained_cnvs => :single do
    return [] if cnvs.empty?
    cnvs.select_by(:gain?)
  end
 
  property :lost_cnvs => :single do
    return [] if cnvs.empty?
    cnvs.select_by(:loss?)
  end

  property :gained_genes => :single do
    return [] if gained_cnvs.empty?
    gained_cnvs.genes.flatten.uniq
  end

  property :lost_genes => :single do
    return [] if lost_cnvs.empty?
    lost_cnvs.genes.flatten.uniq
  end

  property :cnv_genes => :single do
    organism = study.metadata[:organism]
    Gene.setup(lost_genes + gained_genes, "Ensembl Gene ID", organism)
  end

end


