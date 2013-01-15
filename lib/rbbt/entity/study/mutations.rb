task :mutations_by_change => :tsv do
  changes = {}

  study.cohort.each do |genotype|
    genotype.watson ||= watson
    genotype.each do |mutation|
      reference = watson ? mutation.reference : mutation.gene_strand_reference
      base = mutation.base
      base = ((Misc::IUPAC2BASE[base] || []) - [reference]) * ","
      change = [reference, base]
      changes[change * ">"] ||= []
      changes[change * ">"] << mutation.clean_annotations
    end
  end

  TSV.setup(changes, :key_field => "Genomic Change", :fields => ["Genomic Mutation"], :namespace => organism, :type => :flat)

  changes.entity_options = {:watson => watson}

  changes
end


dep :mutations_by_change
task :mutation_change_counts => :yaml do
  change_counts    = {}

  step(:mutations_by_change).load.each do |change, mutations|
    change_counts[change] = mutations.length
  end

  change_counts
end

returns "Genomic Mutation"
task :transversions => :annotations do

  mutations = study.cohort.collect{|genotype| 

    genotype.select{|mutation|

      mutation.type == "transversion"

    } 

  }.flatten

  GenomicMutation.setup(mutations, "#{ study }: transversions", organism, watson)

end

returns "Genomic Mutation"
task :transitions => :annotations do

  mutations = study.cohort.collect{|genotype| 

    genotype.select{|mutation|

      mutation.type == "transition"

    } 

  }.flatten

  GenomicMutation.setup(mutations, "#{ study }: transitions", organism, watson)

end

returns "Genomic Mutation"
task :indels => :annotations do

  mutations = study.cohort.collect{|genotype| 

    genotype.select{|mutation|

      mutation.type == "indel"

    } 

  }.flatten

  GenomicMutation.setup(mutations, "#{ study }: indels", organism, watson)
end

returns "Genomic Mutation"
task :unknown_mutations => :annotations do

  mutations = study.cohort.collect{|genotype| 

    genotype.select{|mutation|

      mutation.type == "unknown"

    } 

  }.flatten

  GenomicMutation.setup(mutations, "#{ study }: unknown_mutations", organism, watson)
end


returns "Genomic Mutation"
task :not_mutations => :annotations do

  mutations = study.cohort.collect{|genotype| 

    genotype.select{|mutation|

      mutation.type == "none"

    } 

  }.flatten

  GenomicMutation.setup(mutations, "#{ study }: not mutations", organism, watson)
end



returns "Genomic Mutation"
task :non_synonymous_mutations => :annotations do

  mutations = study.cohort.collect{|genotype| 

    genotype.select{|mutation|

      (mutation.mutated_isoforms || [] ).select{|mi| mi.non_synonymous }.any? 

    } 

  }.flatten

  GenomicMutation.setup(mutations, "#{ study }: non_synonymous mutations", organism, watson)
end

dep :non_synonymous_mutations
returns "Genomic Mutation"
task :synonymous_mutations => :annotations do
  non_synonymous_mutations = step(:non_synonymous_mutations).load

  mutations = study.cohort.collect{|genotype| 

    genotype.remove( non_synonymous_mutations ) 

  }.flatten

  GenomicMutation.setup(mutations, "#{ study }: synonymous mutations", organism, watson)
end

#dep :synonymous_mutations
#dep :exon_junction_mutations
#input :methods, :array, "Damage prediction methods", [:sift, :mutation_assessor]
#returns "Genomic Mutation"
#task :damaging_mutations => :annotations do |methods|
#  synonymous_mutations = step(:synonymous_mutations).load
#  exon_junction_mutations = step(:exon_junction_mutations).load
#
#  mutations_to_remove = synonymous_mutations - exon_junction_mutations
#
#  mutations = study.cohort.collect{|genotype| 
#
#    genotype.remove( mutations_to_remove ).select{|mutation| mutation.damaging?(methods) } 
#
#  }.flatten
#
#  GenomicMutation.setup(mutations, "#{ study }: damaging mutations", organism, watson)
#end

dep :relevant_mutations
input :methods, :array, "Damage prediction methods", [:sift, :mutation_assessor]
returns "Genomic Mutation"
task :damaging_mutations => :annotations do |methods|
  relevant_mutations = step(:relevant_mutations ).load

  mutations = relevant_mutations.select{|mutation| mutation.damaging?(methods) }

  GenomicMutation.setup(mutations, "#{ study }: damaging mutations", organism, watson)
end


dep :damaging_mutations
dep :relevant_mutations
input :methods, :array, "Damage prediction methods", [:sift]
returns "Genomic Mutation"
task :mutations_missing_predictions => :annotations do |methods|
  damaging_mutations = step(:damaging_mutations).load
  relevant_mutations = step(:relevant_mutations).load

  missing_mutations = relevant_mutations.remove(damaging_mutations)
  missing_mutations_mutated_isoforms = missing_mutations.mutated_isoforms.compact.flatten
  mutated_isoforms_missing_damage_scores = missing_mutations_mutated_isoforms.select{|mis| mis.damage_scores.nil?}
  mutations_missing_predictions = missing_mutations.select{|mutation| mutation.mutated_isoforms and mutation.mutated_isoforms.any?}.select{|mutation| mutation.mutated_isoforms.remove(mutated_isoforms_missing_damage_scores).empty?}
  GenomicMutation.setup(mutations_missing_predictions, "#{ study }: mutations missing predictions", organism, watson)
end

returns "Genomic Mutation"
task :exon_junction_mutations => :annotations do

  mutations = study.cohort.collect{|genotype| 

    genotype.select{|mutation| mutation.transcripts_with_affected_splicing.any? and not mutation.type == "none"} 

  }.flatten

  GenomicMutation.setup(mutations, "#{ study }: exon junction mutations", organism, watson)
end

dep :non_synonymous_mutations
dep :exon_junction_mutations
returns "Genomic Mutation"
task :relevant_mutations => :annotations do
  non_synonymous_mutations = step(:non_synonymous_mutations).load
  exon_junction_mutations = step(:exon_junction_mutations).load

  all_relevant_mutations = ( exon_junction_mutations + non_synonymous_mutations.remove(exon_junction_mutations) ).flatten

  GenomicMutation.setup(all_relevant_mutations, "#{ study }: relevant mutations", organism, watson)
end

dep :relevant_mutations
returns "Genomic Mutation"
task :recurrent_mutations => :annotations do
  relevant_mutations = step(:relevant_mutations).load

  mutations = Misc.counts(relevant_mutations.remove_score).select{|mutation, count| 

    count > 1 

  }.collect{|mutation, count| mutation}

  GenomicMutation.setup(mutations, "#{study}: recurrent mutations", organism, watson)
end

dep :non_synonymous_mutations
task :mutations_by_consequence => :yaml do
  non_synonymous_mutations = step(:non_synonymous_mutations).load

  mutations_by_consequence = {}
  study.cohort.each do |genotype|
    genotype.subset(non_synonymous_mutations).each do |mutation|
      mis = mutation.mutated_isoforms
      next if mis.nil?
      consequences = mis.consequence.compact.uniq
      consequences.each{|consequence| mutations_by_consequence[consequence] ||= []; mutations_by_consequence[consequence] << mutation }
    end
  end

  mutations_by_consequence
end
%w(missense_mutations nonsense_mutations frameshift_mutations nostop_mutations indel_mutations utr_mutations ).zip(
  %w(MISS-SENSE NONSENSE FRAMESHIFT NOSTOP INDEL UTR)).each do |task_name, consequence|
  dep :mutations_by_consequence
  returns "Genomic Mutation"
  task task_name => :annotations do
    mutations_by_consequence = step(:mutations_by_consequence).load
    GenomicMutation.setup(mutations_by_consequence[consequence] || [], "#{study}: mutations with #{consequence.downcase} isoform mutations", organism, watson)
  end
end

