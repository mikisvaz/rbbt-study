require 'rbbt/entity/cnv'

require 'rbbt/entity/study/cnv/genes'
require 'rbbt/entity/study/cnv/samples'

module StudyWorkflow
  helper :organism do
    study.metadata[:organism]
  end

  task :cnv_overview => :tsv do
    gene_overview = TSV.setup({}, 
                          :key_field => "Ensembl Gene ID", 
                          :fields => ["Samples with gene lost", "Samples with gene gained"],
                          :type => :double
                         )

    cnv_samples = study.samples.select_by(:has_cnv?)

    log :samples, "Gathering affected samples"
    samples_gene_status = {}
    all_genes = []
    cnv_samples.each do |sample|
      samples_gene_status[sample] = {}

      lost_genes = sample.lost_genes
      lost_genes.clean_annotations.each do |gene|
        samples_gene_status[sample][gene] ||= [false, false]
        samples_gene_status[sample][gene][0] = true
        all_genes << gene
      end if lost_genes.any?

      gained_genes = sample.gained_genes
      gained_genes.clean_annotations.each do |gene|
        samples_gene_status[sample][gene] ||= [false, false]
        samples_gene_status[sample][gene][1] = true
        all_genes << gene
      end if gained_genes.any?
    end

    log :compiling, "Compiling result"
    all_genes.uniq.sort.each do |gene|
      gene_overview[gene] = []
      gene_overview[gene] << samples_gene_status.select{|sample, gene_status| gene_status.include? gene and gene_status[gene][0]}.collect{|sample, gene_status| sample}
      gene_overview[gene] << samples_gene_status.select{|sample, gene_status| gene_status.include? gene and gene_status[gene][1]}.collect{|sample, gene_status| sample} 
    end

    gene_overview
  end
end

module Study
  def has_cnv?
    dir.cnv.exists?
  end

  def cnv_files
    dir.cnv.find.glob("*")
  end

  def cnv_cohort
    if @cnv_cohort.nil?
      @cnv_cohort = {}
      cnv_files.each do |f| 
        sample = File.basename(f)
        Sample.setup(sample, self)
        cnvs = Open.read(f).split("\n").sort
        CNV.setup(cnvs, organism)
        @cnv_cohort[sample] =  cnvs
      end
    end
    @cnv_cohort
  end
end

module Study
  property :recurrently_lost_genes => :single do |threshold|
    counts = {}
    self.samples.each do |sample|
      next unless sample.has_cnvs?
      puts sample

      genes = nil
      genes = sample.lost_genes.clean_annotations
      genes.each do |gene|
        counts[gene] ||= 0
        counts[gene] += 1 
      end
    end

    recurrent = counts.select{|k,c| c >= threshold }.collect{|k,v| k }
    Gene.setup(recurrent, "Ensembl Gene ID", organism)
  end

  property :recurrently_gained_genes => :single do |threshold|
    counts = {}
    self.samples.each do |sample|
      next unless sample.has_cnvs?
      puts sample

      genes = nil
      genes = sample.gained_genes.clean_annotations
      genes.each do |gene|
        counts[gene] ||= 0
        counts[gene] += 1 
      end
    end

    recurrent = counts.select{|k,c| c >= threshold }.collect{|k,v| k }
    Gene.setup(recurrent, "Ensembl Gene ID", organism)
  end

  property :gene_sample_cnv_matrix => :single do
    tsv = TSV.setup({}, :key_field => "Ensembl Gene ID", :namespace => organism, :type => :list)
    samples = []
    i = 0
    num_samples = cohort.length
    cnv_cohort.each do |sample,cnvs|
      cnvs.genes.compact.flatten.uniq.each do |gene|
        tsv[gene] ||= ["FALSE"] * num_samples
        tsv[gene][i] = "TRUE"
      end
      samples << sample
      i += 1
    end

    tsv.fields = samples

    tsv
  end

  property :gene_sample_gain_matrix => :single do
    tsv = TSV.setup({}, :key_field => "Ensembl Gene ID", :namespace => organism, :type => :list)
    samples = []
    i = 0
    num_samples = cohort.length
    cnv_cohort.each do |sample,cnvs|
      cnvs.select_by(:gain?).genes.compact.flatten.uniq.each do |gene|
        tsv[gene] ||= ["FALSE"] * num_samples
        tsv[gene][i] = "TRUE"
      end
      samples << sample
      i += 1
    end

    tsv.fields = samples

    tsv
  end


  property :gene_sample_loss_matrix => :single do
    tsv = TSV.setup({}, :key_field => "Ensembl Gene ID", :namespace => organism, :type => :list)
    samples = []
    i = 0
    num_samples = cohort.length
    cnv_cohort.each do |sample,cnvs|
      cnvs.select_by(:loss?).genes.compact.flatten.uniq.each do |gene|
        tsv[gene] ||= ["FALSE"] * num_samples
        tsv[gene][i] = "TRUE"
      end
      samples << sample
      i += 1
    end

    tsv.fields = samples

    tsv
  end
end
