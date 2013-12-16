require 'rbbt/entity/genotype'

require 'rbbt/entity/study/genotypes/samples'
require 'rbbt/entity/study/genotypes/mutations'
require 'rbbt/entity/study/genotypes/genes'
require 'rbbt/entity/study/genotypes/enrichment'
require 'rbbt/entity/study/genotypes/knowledge_base'

Workflow.require_workflow "NKIWorkflow"

module StudyWorkflow
  helper :organism do
    study.metadata[:organism]
  end

  task :binomial_significance => :tsv do

    tsv = TSV.setup({}, :key_field => "Ensembl Gene ID", :fields => ["Matches", "Bases", "Frequency", "p.value"], :namespace => organism)

    matches = study.knowledge_base.get_index(:mutation_genes).keys
    genes = matches.collect{|m| m.partition("~").last}.uniq
    all_mutations = matches.collect{|m| m.partition("~").first}.uniq

    total_bases = Gene.gene_list_exon_bases(genes)
    global_frequency = all_mutations.length.to_f / total_bases

    gene2exon_size = Misc.process_to_hash(genes){|genes| genes.collect{|gene| Gene.gene_list_exon_bases([gene]) }}

    genes.each do |gene|
      mutations = study.knowledge_base.parents(:mutation_genes, gene).target
      mutations = study.knowledge_base.subset(:sample_mutations, "Genomic Mutation" => mutations, "Sample" => :all).source
      next if mutations.empty?
      matches = mutations.length
      exon_bases = gene2exon_size[gene]
      next if exon_bases == 0
      frequency = matches.to_f / exon_bases
      pvalue = RSRuby.instance.binom_test(matches, exon_bases, global_frequency, 'greater')["p.value"]
      tsv[gene] = [matches, exon_bases, frequency, pvalue]
    end

    tsv
  end

  task :genotype_overview => :tsv do
    gene_overview = TSV.setup({}, 
                          :key_field => "Ensembl Gene ID", 
                          :fields => ["Samples with gene mutated", "Samples with gene affected", "Samples with gene damaged", "Mutation significance"],
                          :type => :double
                         )
    genotyped_samples = study.samples.select_by(:has_genotype?)
    all_mutations = study.all_mutations
    if all_mutations.empty?
      gene_overview 
    else

      log :affected_genes, "Computing how genes are affected by mutations"
      mutation_genes = Misc.process_to_hash(all_mutations){|all_mutations| all_mutations.genes}
      mutation_affected_genes = Misc.process_to_hash(all_mutations){|all_mutations| all_mutations.affected_genes}
      if all_mutations.length < 5000
        log :damaged_genes, "Computing damaged genes"
        mutation_damaged_genes = Misc.process_to_hash(all_mutations){|all_mutations| all_mutations.damaged_genes}
      else
        mutation_damaged_genes = Misc.process_to_hash(all_mutations){|all_mutations| [nil] * all_mutations.length}
      end
      log :significance, "Computing mutation significance"
      mutation_significance = NKIWorkflow.job(:significantly_mutated, study, :study => study, :threshold => 0.1).run
      log :significance, "Reordering mutation significance file"

      mutation_significance.identifiers = Organism.identifiers(study.organism)
      mutation_significance = mutation_significance.change_key "Ensembl Gene ID" 

      log :samples, "Gathering affected samples"
      samples_gene_status = {}
      genotyped_samples.each do |sample|
        samples_gene_status[sample] = {}

        mutation_genes.values_at(*sample.mutations).each do |genes|
          genes.each do |gene|
            samples_gene_status[sample][gene] ||= [false, false, false]
            samples_gene_status[sample][gene][0] = true
          end
        end

        mutation_affected_genes.values_at(*sample.mutations).each do |genes|
          genes.each do |gene|
            samples_gene_status[sample][gene] ||= [false, false, false]
            samples_gene_status[sample][gene][1] = true
          end
        end

        mutation_damaged_genes.values_at(*sample.mutations).each do |genes|
          next if genes.nil?
          genes.each do |gene|
            samples_gene_status[sample][gene] ||= [false, false, false]
            samples_gene_status[sample][gene][2] = true
          end 
        end
      end

      log :compiling, "Compiling result"
      mutation_genes.values.compact.flatten.uniq.each do |gene|
        gene_overview[gene] = []
        gene_overview[gene] << samples_gene_status.select{|sample, gene_status| gene_status.include? gene and gene_status[gene][0]}.collect{|sample, gene_status| sample}
        gene_overview[gene] << samples_gene_status.select{|sample, gene_status| gene_status.include? gene and gene_status[gene][1]}.collect{|sample, gene_status| sample} 
        gene_overview[gene] << samples_gene_status.select{|sample, gene_status| gene_status.include? gene and gene_status[gene][2]}.collect{|sample, gene_status| sample} 
        gene_overview[gene] << [mutation_significance.include?(gene) ? mutation_significance[gene]["p.value"] : "> 0.1"]
      end

      gene_overview
    end
  end
end

module Study
  def has_genotypes?
    dir.genotypes.exists?
  end

  attr_accessor :watson
  def watson
    @watson  = metadata[:watson] if @watson.nil?
    @watson
  end

  def genotype_files
    dir.genotypes.glob("*")
  end

  def cohort
    @cohort ||= genotype_files.collect do |f| 
      name = File.basename(f)
      genomic_mutations = Open.read(f).split("\n").sort
      GenomicMutation.setup(genomic_mutations, name, organism, watson)
    end.tap{|cohort| cohort.extend Genotype::Cohort}
  end
end
