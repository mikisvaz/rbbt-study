module Study

  property :samples_with_gene_gained => :single do
    samples_with_gene_gained = {}
    self.job(:cnv_overview).run.through do |gene, values|
      values.fields.zip(values).each do |sample, value|
        next unless value == "Gained"
        samples_with_gene_gained[gene] ||= []
        samples_with_gene_gained[gene] << sample
      end
    end
    samples_with_gene_gained
  end
  

  property :samples_with_gene_lost => :single do
    samples_with_gene_lost = {}
    self.job(:cnv_overview).run.through do |gene, values|
      values.fields.zip(values).each do |sample, value|
        next unless value == "Lost"
        samples_with_gene_lost[gene] ||= []
        samples_with_gene_lost[gene] << sample
      end
    end
    samples_with_gene_lost
  end
  
end
