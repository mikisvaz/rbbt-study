input :cutoff, :integer, "Pixels of image", 2
input :size, :integer, "Pixels of image", 14
task :gene_mutation_plot => :binary do |cutoff, size|
  png_file = file(study + ".png")
  FileUtils.mkdir_p File.dirname png_file unless File.exists? File.dirname png_file
  study.R "
library(ggplot2)
library(plyr)
library(reshape)

layer.mutations = rbbt.SE.plot.mutations('#{study}', cutoff=#{cutoff});
p <- ggplot() + layer.mutations 

p <- p + opts(axis.text.x=theme_text(angle=90), panel.background = theme_rect(fill='white', colour='steelblue'))

ggsave(p, filename='#{png_file}', height=#{size}, width=#{size});
"
  Open.read(png_file, :mode => 'rb')
end


input :database, :string, "Database code", :kegg
input :size, :integer, "Pixels of image", 14
task :pathway_mutation_plot => :binary do |database,size|
  png_file = file(study + ".png")
  FileUtils.mkdir_p File.dirname png_file unless File.exists? File.dirname png_file
  study.R "
library(ggplot2)
library(plyr)
library(reshape)


study = '#{study}'
# Sample mutations
sample.mutated.genes = rbbt.SE.sample.mutated.genes(study)
sample.mutated.genes$Sample = rownames(sample.mutated.genes)

# Pathway enrichment
pathway.enrichment = rbbt.ruby.substitutions(
    \"
    require 'rbbt/workflow'
    require 'rbbt/entity'
    require 'rbbt/entity/gene'
    require 'rbbt/sources/pfam'
    require 'rbbt/sources/kegg'
    require 'rbbt/sources/go'

    YAML::ENGINE.yamler = 'syck' if defined? YAML::ENGINE and YAML::ENGINE.respond_to? :yamler

    Workflow.require_workflow 'StudyExplorer'

    study = Study.setup('STUDY')

    pathways = study.job(:mutation_pathway_enrichment, study, :baseline => :pathway_base_counts, :database => '#{database}', :fdr => false).run.select('p-value'){|pvalue| pvalue = pvalue.first.to_f if Array === pvalue; pvalue < 0.2}
    pathways.add_field 'Name' do |pathway, values|
        [pathway.name]
    end

    pathways.add_field 'Gene' do |pathway, values|
        values['Ensembl Gene ID'].name
    end

    pathways = pathways.select('Name'){|name| name.first.to_s !~ /cancer|olfactory|glioma|melanoma|malaria|leukemia|carcinoma|sarcoma/i}

    \", substitutions=list(STUDY=study));


# Sample pathway mutations
find.mutated.pathways.for.sample <- function(x, pathway.info){
    all.genes = names(x);
    genes = all.genes[x==TRUE];
    ddply(pathway.info, 'Name', function(x){pathway.genes = unlist(strsplit(x$Gene, '\\\\|')); if (length(intersect(genes, pathway.genes)) > 0){TRUE}else{FALSE}})
}
sample.pathway.mutations = ddply(sample.mutated.genes, 'Sample', find.mutated.pathways.for.sample, pathway.info = pathway.enrichment)
names(sample.pathway.mutations) = c('Sample', 'Pathway', 'Mutated')

p <- ggplot(sample.pathway.mutations) + geom_tile(aes(x=Sample, y=Pathway, alpha=Mutated))

p <- rbbt.SE.plot.sort.by.pathway.mutations(p)


# Mark repeated genes


d = p$data
d$Exclusive = FALSE

pathway.genes = list();
for(pathway in levels(d$Pathway)){
   pathway.genes[pathway] = strsplit(pathway.enrichment[pathway.enrichment[,'Name'] == pathway, 'Gene'], '\\\\|')
}

find.exclusive.pathway.genes <- function(data, pathways){
  found.genes = c();
  exclusive.pathway.genes = list();
  sample = as.character(unique(data$Sample));
  for(pathway in pathways){
     current.pathway.genes = pathway.genes[[pathway]];
     sample.genes = names(sample.mutated.genes)[sample.mutated.genes[sample,] == TRUE]
     sample.pathway.genes = intersect(current.pathway.genes, sample.genes);
     exclusive.genes = setdiff(sample.pathway.genes, found.genes);
     found.genes = c(found.genes, exclusive.genes)
     exclusive.pathway.genes[[pathway]] = exclusive.genes
  }

  return(exclusive.pathway.genes);
}

exclusive.pathway.genes = dlply(d, 'Sample', find.exclusive.pathway.genes, pathways = levels(d$Pathway)) 

for( sample in names(exclusive.pathway.genes)){
     pathway.exclusive.genes = exclusive.pathway.genes[[sample]];
     for( pathway in names(pathway.exclusive.genes)){
        if (length(pathway.exclusive.genes[[pathway]]) > 0){
           print(sample)
           print(pathway)
           d[(d$Sample == sample & d$Pathway == pathway), 'Exclusive'] = TRUE
        }
     }
}

p$data = d


p <- p + aes(fill=Exclusive)

p <- p + opts(axis.text.x=theme_text(angle=90), panel.background = theme_rect(fill='white', colour='steelblue'))

p




ggsave(p, filename='#{png_file}', height=#{size}, width=#{size});
"
  Open.read(png_file, :mode => 'rb')
end



