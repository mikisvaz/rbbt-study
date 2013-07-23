module StudyWorkflow
  helper :organism do
    study.metadata[:organism]
  end

  task :matrix => :tsv do
    matrix = study.matrix("gene_expression", "Ensembl Gene ID", organism)
    matrix.matrix_file(path)
    nil
  end

  task :expression_barcode => :tsv do
    matrix = study.matrix("gene_expression", "Ensembl Gene ID", organism)
    matrix.barcode(path)
    nil
    
    #script =<<-EOF
    #  data = rbbt.tsv('#{step(:matrix).path}')
    #  data.mean = rowMeans(data, na.rm=T)
    #  data.sd = apply(data, 1, sd, na.rm=T)
    #  data.threshold = as.matrix(data.mean) + 3 * as.matrix(data.sd)
    #  rm(data.mean)
    #  rm(data.sd)

    #  file.barcode = file('#{path}', 'w')

    #  cat("#Ensembl Gene ID", file = file.barcode)
    #  cat("\\t", file = file.barcode)
    #  cat(colnames(data), file = file.barcode, sep="\\t")
    #  cat("\\n", file = file.barcode)
    #     
    #  i = 1
    #  for (gene in rownames(data)){
    #    print(i)
    #    i = i + 1
    #    barcode = (data[gene,] - data.threshold) > 0

    #    cat(gene, file = file.barcode)
    #    cat("\\t", file = file.barcode)
    #    cat(barcode, file = file.barcode, sep = "\\t")
    #    cat("\\n", file = file.barcode)
    #  }
    #  close(file.barcode)
    #EOF

    #R.run(script , :pipe => true, :monitor => true)
  end
end

