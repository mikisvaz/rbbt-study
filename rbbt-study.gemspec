# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: rbbt-study 0.2.11 ruby lib

Gem::Specification.new do |s|
  s.name = "rbbt-study"
  s.version = "0.2.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Miguel Vazquez"]
  s.date = "2013-11-14"
  s.description = "This gem add the study entity with suport for NGS, Microarray and other types of data"
  s.email = "miguel.vazquez@cnio.es"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc"
  ]
  s.files = [
    "lib/rbbt/entity/study.rb",
    "lib/rbbt/entity/study/cnv.rb",
    "lib/rbbt/entity/study/cnv/genes.rb",
    "lib/rbbt/entity/study/cnv/samples.rb",
    "lib/rbbt/entity/study/enrichment.rb",
    "lib/rbbt/entity/study/expression.rb",
    "lib/rbbt/entity/study/features.rb",
    "lib/rbbt/entity/study/genes.rb",
    "lib/rbbt/entity/study/genotypes.rb",
    "lib/rbbt/entity/study/genotypes/enrichment.rb",
    "lib/rbbt/entity/study/genotypes/genes.rb",
    "lib/rbbt/entity/study/genotypes/knowledge_base.rb",
    "lib/rbbt/entity/study/genotypes/mutations.rb",
    "lib/rbbt/entity/study/genotypes/samples.rb",
    "lib/rbbt/entity/study/knowledge_base.rb",
    "lib/rbbt/entity/study/methylation.rb",
    "lib/rbbt/entity/study/methylation/samples.rb",
    "lib/rbbt/entity/study/mutations.rb",
    "lib/rbbt/entity/study/plots.rb",
    "lib/rbbt/entity/study/samples.rb",
    "lib/rbbt/entity/study/snp.rb"
  ]
  s.homepage = "http://github.com/mikisvaz/rbbt-study"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.0"
  s.summary = "Genomic study entity"
end

