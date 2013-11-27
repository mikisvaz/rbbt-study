module StudyWorkflow
  helper :organism do
    study.metadata[:organism]
  end

  task :matrix => :tsv do
    matrix = study.matrix("gene_expression", "Ensembl Gene ID", organism)
    matrix.matrix_file(path)
    nil
  end

  task :expression_barcode => :tsv do |*args|
    factor = args.first || 2
    matrix = study.matrix("gene_expression", "Ensembl Gene ID", organism)
    matrix.barcode(path, factor)
    nil
  end
end

module Study
  def has_expression?
    dir.matrices["gene_expression"].exists?
  end
end
