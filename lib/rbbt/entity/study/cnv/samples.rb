module Sample
  property :cnvs => :array2single do
    study.cnv_cohort
  end

  property :has_cnv? => :array2single do
    study.cnv_cohort.values_at(*self).collect{|cnvs| not cnvs.nil?}
  end

  property :gene_CN => :single do
    gene_CN = {}
    cnvs.variation.zip(cnvs.genes).each do |var, genes|
      next if genes.empty?
      genes = Annotated.purge genes 
      case var
      when "loss"
        genes.each{|gene| gene_CN[gene] = "Lost"}
      when "gain"
        genes.each{|gene| gene_CN[gene] = "Gained"}
      end
    end
    gene_CN
  end
  persist :gene_CN
  
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
    Gene.setup(gene_CN.select{|g,v| v == "Gained"}.collect{|g,v| g}, "Ensembl Gene ID", self.study.organism)
  end

  property :lost_genes => :single do
    Gene.setup(gene_CN.select{|g,v| v == "Lost"}.collect{|g,v| g}, "Ensembl Gene ID", self.study.organism)
  end

  property :cnv_genes => :single do
    return nil if lost_genes.nil? or gained_genes.nil?
    organism = study.metadata[:organism]
    Gene.setup((lost_genes + gained_genes).uniq, "Ensembl Gene ID", lost_genes.organism)
  end

end


