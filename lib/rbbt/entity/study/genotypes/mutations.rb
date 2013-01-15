module Study
  property :all_mutations do
    cohort.metagenotype.tap{|o| o.jobname = "All mutations in #{ self }" }
  end

  property :relevant_mutations do
    all_mutations = self.all_mutations

    all_mutations.select{|m| m.relevant? }.
      tap{|o| o.jobname = "Relevant mutations in #{ self }" }
  end

  property :damaging_mutations do |*args|
    relevant_mutations.select{|m| m.damaging?(*args) }.tap{|o| o.jobname = "Damaging mutations in #{ self }" }
  end

  property :mutations_altering_isoform_sequence do
    relevant_mutations.select{|m| 
      mis = m.mutated_isoforms; not mis.nil? and mis.select{|m| m.consequence != "SYNONYMOUS"}.any?
    }.tap{|o| o.jobname = "Mutations altering isoform sequence in #{ self }"}
  end

  property :mutations_affecting_splicing_sites do
    relevant_mutations.select{|m| m.transcripts_with_affected_splicing.any? }.
      tap{|o| o.jobname = "Mutations affecting splicing sites in #{ self }"}
  end

end
