library(tidyverse)
library(qgraph)
library(RColorBrewer)
library(gplots)

setwd("/proj/jmsimon/Neuroscience")
copub_counts <- read_tsv("NBIO_curriculum_faculty_list_2023-03-08_coPublication_table_counts.txt")

all_authors <- unique(c(copub_counts$Author1,copub_counts$Author2))

mat <- matrix(data=0,nrow=length(all_authors),ncol=length(all_authors))
rownames(mat) <- all_authors
colnames(mat) <- all_authors

for(i in 1:length(rownames(copub_counts))) {
	mat[which(rownames(mat)==as.character(copub_counts[i,1])),which(colnames(mat)==as.character(copub_counts[i,2]))] = as.numeric(copub_counts[i,3])
}

pdf("NBIO_curriculum_faculty_list_2023-03-08_coPublication_networks.pdf",width=20,height=20)
qgraph(mat,
	layout="spring",
	directed=F,
	labels=rownames(mat),
	edge.color="black",
	curve=0,
	label.cex=3,
	label.scale.equal=T)
dev.off()
