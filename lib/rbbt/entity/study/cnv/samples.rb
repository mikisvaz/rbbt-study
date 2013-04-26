module Sample
  property :cnvs => :array2single do
    study.cnv_cohort
  end

  property :has_cnvs? => :array2single do
    study.cnv_cohort.values_at(*self).collect{|cnvs| not cnvs.nil?}
  end
  
  property :gained_cnvs => :single do
    return nil if cnvs.nil?
    return [] if cnvs.empty?
    cnvs.select_by(:gain?)
  end
 
  property :lost_cnvs => :single do
    return nil if cnvs.nil?
    return [] if cnvs.empty?
    cnvs.select_by(:loss?)
  end

  property :gained_genes => :single do
    return nil if gained_cnvs.nil?
    return [] if gained_cnvs.empty?
    Gene.setup(gained_cnvs.genes.flatten.uniq, "Ensembl Gene ID", gained_cnvs.organism)
  end

  property :lost_genes => :single do
    return nil if lost_cnvs.nil?
    return [] if lost_cnvs.empty?
    Gene.setup(lost_cnvs.genes.flatten.uniq, "Ensembl Gene ID", lost_cnvs.organism)
  end

  property :cnv_genes => :single do
    return nil if lost_genes.nil? or gained_genes.nil?
    organism = study.metadata[:organism]
    Gene.setup((lost_genes + gained_genes).uniq, "Ensembl Gene ID", lost_genes.organism)
  end

end


