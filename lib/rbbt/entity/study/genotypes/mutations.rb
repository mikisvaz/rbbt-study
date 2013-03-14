module Study
  property :all_mutations do
    cohort.metagenotype.tap{|o| o.jobname = "All mutations in #{ self }" }
  end

  property :relevant_mutations do
    all_mutations = self.all_mutations

    all_mutations.select_by(:relevant?).tap{|o| o.jobname = "Relevant mutations in #{ self }" }
  end

  property :damaging_mutations do |*args|
    relevant_mutations.select_by(:damaging?, *args).tap{|o| o.jobname = "Damaging mutations in #{ self }" }
  end

  property :mutations_altering_isoform_sequence do
    relevant_mutations.select{|m| 
      mis = m.mutated_isoforms; not mis.nil? and mis.select{|m| m.consequence != "SYNONYMOUS"}.any?
    }.tap{|o| o.jobname = "Mutations altering isoform sequence in #{ self }"}
  end

  property :mutations_affecting_splicing_sites do
    relevant_mutations.select_by(:transcripts_with_affected_splicing){|ts| ts.any? }.
      tap{|o| o.jobname = "Mutations affecting splicing sites in #{ self }"}
  end

  property :mutations_over_gene do |gene|
    all_mutations.select_by(:genes){|genes| genes and genes.include? gene}
  end

  property :mutations_over_gene_list do |list|
    all_mutations.select_by(:genes){|genes| genes and (genes & list).any?}
  end
end
