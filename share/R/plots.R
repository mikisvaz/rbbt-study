rbbt.SE.plot.sort.by.field <- function(plot, field){
    d = plot$data;

    d[[field]] = reorder(d[[field]], d$Mutated, sum)

    sample.best.gene.pos.df = ddply(d, "Sample", function(x){ min(match(subset(x, Mutated==TRUE)[[field]], rev(levels(d[[field]]))), na.rm=T)})

    d$sample.best.gene.pos = NULL
    names(sample.best.gene.pos.df) <- c("Sample", "sample.best.gene.pos");

    d = merge(d, sample.best.gene.pos.df, all.x=TRUE)

    d$Sample = reorder(d$Sample, d$sample.best.gene.pos)

    plot$data = d;

    return(plot);
}

rbbt.SE.plot.sort.by.mutations <- function(plot){
    d = plot$data;

    d$Gene = reorder(d$Gene, d$Mutated, sum);
    num.elems = length(levels(d$Gene));

    #sample.best.gene.pos.df = ddply(d, "Sample", function(x){ 1/mean(1/match(subset(x, Mutated==TRUE)$Gene, rev(levels(d$Gene)))^2)})
    sample.best.gene.pos.df = ddply(d, "Sample", function(x){ 1/sum(2^(num.elems - match(subset(x, Mutated==TRUE)$Gene, rev(levels(d$Gene)))))})

    d$sample.best.gene.pos = NULL
    names(sample.best.gene.pos.df) <- c("Sample", "sample.best.gene.pos");

    d = merge(d, sample.best.gene.pos.df, all.x=TRUE)

    d$Sample = reorder(d$Sample, d$sample.best.gene.pos)

    plot$data = d;

    return(plot);
}

rbbt.SE.plot.sort.by.pathway.mutations <- function(plot){
    d = plot$data;

    d$Pathway = reorder(d$Pathway, d$Mutated, sum);
    num.elems = length(levels(d$Pathway));

    #sample.best.gene.pos.df = ddply(d, "Sample", function(x){ min(match(subset(x, Mutated==TRUE)$Pathway, rev(levels(d$Pathway))), na.rm=T)})
    #sample.best.gene.pos.df = ddply(d, "Sample", function(x){ 1/mean(1/match(subset(x, Mutated==TRUE)$Pathway, rev(levels(d$Pathway)))^2)})
    sample.best.gene.pos.df = ddply(d, "Sample", function(x){ 1/sum(2^(num.elems - match(subset(x, Mutated==TRUE)$Pathway, rev(levels(d$Pathway)))))})

    d$sample.best.gene.pos = NULL
    names(sample.best.gene.pos.df) <- c("Sample", "sample.best.gene.pos");

    d = merge(d, sample.best.gene.pos.df, all.x=TRUE)

    d$Sample = reorder(d$Sample, d$sample.best.gene.pos)

    plot$data = d;

    return(plot);
}

rbbt.SE.plot.mutations <- function(study, cutoff = 3, sample.info = NULL){
    sample.mutated.genes = rbbt.SE.sample.mutated.genes(study);

    gene.mutation.counts = apply(sample.mutated.genes, 2, function(x){sum(x==TRUE)})

    recurrent.genes = names(gene.mutation.counts[gene.mutation.counts >= cutoff])

    d.recurrent = sample.mutated.genes[, recurrent.genes]
    d.recurrent$Sample = rownames(d.recurrent)

    d.recurrent.m = melt(d.recurrent, "Sample")

    names(d.recurrent.m) <- c("Sample", "Gene", "Mutated")

    if (is.null(sample.info)){
        d = d.recurrent.m
    }else{
        d = merge(d.recurrent.m, sample.info, all.x=TRUE)
    }

    layer.mutations = geom_tile(data=d,aes(x=Sample, y=Gene, alpha=Mutated))

    rbbt.SE.plot.sort.by.mutations(layer.mutations);

    return(layer.mutations);
}

rbbt.SE.plot.add.expression <- function(plot, study, ...){

    genes = unique(plot$data$Gene);
    gene.expression <- rbbt.SE.expression(study, genes, ...);

    gene.expression.m <- melt(gene.expression);
    names(gene.expression.m) <- c("Gene", "Sample", "Expression");

    gene.expression.3rd = summary(gene.expression.m$Expression)[["3rd Qu."]]
    gene.expression.1st = summary(gene.expression.m$Expression)[["1st Qu."]]

    unpadd = as.character(as.numeric(gene.expression.m$Sample));
    unpadd[is.na(unpadd)] = gene.expression.m$Sample[is.na(unpadd)];
    gene.expression.m$Sample = unpadd;

    mean.gene.expression <- aggregate(Expression ~ Gene, gene.expression.m, mean, trim=0.1, na.rm=T);
    names(mean.gene.expression) <- c("Gene", "Mean");
    gene.expression.m[gene.expression.m[,"Expression"] > gene.expression.3rd, "Expression"] = gene.expression.3rd
    gene.expression.m[gene.expression.m[,"Expression"] < gene.expression.1st, "Expression"] = gene.expression.1st

    sd.gene.expression <- aggregate(Expression ~ Gene, gene.expression.m, mad, na.rm=T);
    names(sd.gene.expression) <- c("Gene", "SD");

    gene.expression.m <- merge(gene.expression.m, mean.gene.expression);
    gene.expression.m <- merge(gene.expression.m, sd.gene.expression);

    #d = merge(d, gene.expression.m, by=c("Sample", "Gene"), all.x=TRUE);
    plot$data = merge(plot$data, gene.expression.m, all.x=TRUE);

    layer.expression = geom_point(data=plot$data, aes(x=Sample, y=Gene, size=abs((Expression - Mean) / SD), color=((Expression - Mean) / SD)));
 
    return(layer.expression)
}
