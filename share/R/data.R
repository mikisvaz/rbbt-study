rbbt.SE.sample.mutated.genes <- function(study){
    sample.mutated.genes <- rbbt.ruby.substitutions(
        "
        require 'rbbt/workflow'
        Workflow.require_workflow 'StudyExplorer'

        YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE and YAML::ENGINE.respond_to? :yamler

        Log.severity = 0

        study = Study.setup('STUDY')

        relevant_genes = study.job(:relevant_genes, study).run.uniq

        tsv = TSV.setup({}, :key_field => 'Sample', :fields => relevant_genes.name, :type => :single)

        study.cohort.each do |genotype|
            sample = genotype.jobname
            mutated_genes = genotype.genes.compact.flatten.uniq
            tsv[sample] = relevant_genes.collect{|gene| mutated_genes.include?(gene)? 'TRUE' : 'FALSE' }
        end

        tsv
        ", substitutions = list(STUDY=study))
}

rbbt.SE.gene.kegg.pathway <- function(genes){
    gene_str = rbbt.a.to.string(genes);
    gene.pathways = rbbt.ruby.substitutions(
        "
        require 'rbbt/entity/gene'
        require 'rbbt/sources/kegg'

        YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE and YAML::ENGINE.respond_to? :yamler

        Log.severity=0

        genes = [GENE_STR];

        Gene.setup(genes, 'Associated Gene Name', Organism.default_code('Hsa'))

        pathways = genes.kegg_pathways.compact.flatten.uniq

        gene_pathways = {}
        genes.each do |gene|
            gene_pathway_list = gene.kegg_pathways || []
            gene_pathways[gene] = pathways.collect{|p| gene_pathway_list.include?(p) ? 1 : 0 }
        end

        tsv = TSV.setup(gene_pathways, :key_field => 'Associated Gene Name', :fields => [pathways], :type => :flat)
        ", substitutions = list(GENE_STR=gene_str));

    gene.pathways$Gene = rownames(gene.pathways)

    return(gene.pathways)
}

rbbt.SE.study.samples <- function(study){
    samples <- rbbt.ruby.substitutions(
        "
        require 'rbbt/workflow'
        Workflow.require_workflow 'StudyExplorer'

        YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE and YAML::ENGINE.respond_to? :yamler

        Log.severity = 0

        study = Study.setup('STUDY')

        study.samples
        ", substitutions = list(STUDY=study));

    return(samples);
}


