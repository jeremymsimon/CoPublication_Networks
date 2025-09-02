suppressPackageStartupMessages(library(reutils))
suppressPackageStartupMessages(library(XML))
suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(readxl))
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(tools))
suppressPackageStartupMessages(library(qgraph))

# Parse input options
option_list <- list( 
    make_option(c("-i", "--input"), 
		type="character",
		default=NA,
        help="Required. Filename of input table containing faculty names\n\t\tMust be tab-delimited text or xlsx\n\t\t\tColumn 1: AuthorLast AuthorFirst\n\t\t\tColumn 2: AuthorLast AuthorFirstInitial\n\t\t\tColumn 3: Primary affiliation",
        metavar="FILENAME"),
    make_option("--minyear", 
		type="double", 
		default=NA,
        help = "Required. Beginning year of date range for query (YYYY)",
        metavar="MINYEAR"),
    make_option("--maxyear", 
		type="double", 
		default=NA,
        help="Required. End year of date range for query (YYYY)",
        metavar="MAXYEAR"),
    make_option(c("-k","--apikey"),
		type="character",
		help="Optional. NCBI API key for large queries, [default %default]\n\t\tHIGHLY recommended, refer to E-utilities documentation here:\n\t\t\thttps://www.ncbi.nlm.nih.gov/books/NBK25497/",
		metavar="APIKEY",
		default=NULL)
)

opt <- parse_args(OptionParser(option_list=option_list))

# Check required input parameters were provided
if (!is.na(opt$minyear)) {
	mindate <- opt$minyear
} else {
	print_help(OptionParser(option_list=option_list))
	stop("minyear parameter must be provided. See script usage (--help)")
}

if (!is.na(opt$maxyear)) {
        maxdate <- opt$maxyear
} else {
	print_help(OptionParser(option_list=option_list))
	stop("maxyear parameter must be provided. See script usage (--help)")
}

if (!is.na(opt$input)) {
        input <- opt$input
} else {
	print_help(OptionParser(option_list=option_list))
	stop("input filename must be provided. See script usage (--help)")
}


# Set NCBI API key if provided
if(!is.null(opt$apikey)) {
	options(reutils.api.key = opt$apikey)
}

# Import author table
if(file_ext(input)=="xlsx") {
	input_list <- read_excel(input,col_names=c("Full","Short","Affiliation"))
} else{
	input_list <- read_tsv(input,col_names=c("Full","Short","Affiliation"))
}


# Perform pubmed queries
results_full <- c()
results_counts <- c()

for(i in 1:length(input_list$Full)) {
	for(j in 1:length(input_list$Full)) {
		if(i==j) next
		# Incorporate sleeps to slow down queries and avoid overloading server
		if(i %% 2 == 0 || j %% 2 == 0) {
			Sys.sleep(10)
		}
		
		auth1_full <- as.character(input_list[i,"Full"])
		auth2_full <- as.character(input_list[j,"Full"])
		auth1_short <- as.character(input_list[i,"Short"])
		auth2_short <- as.character(input_list[j,"Short"])
		auth1_affl <- as.character(input_list[i,"Affiliation"])
		auth2_affl <- as.character(input_list[j,"Affiliation"])

		term <- paste0("(",auth1_full, " [AUTH] ",auth1_affl," [AFFL] OR ",auth1_short," [AUTH] ",auth1_affl," [AFFL]) AND (",auth2_full, " [AUTH] ",auth2_affl," [AFFL] OR ",auth2_short," [AUTH] ",auth2_affl, " [AFFL])")
		print(term)
		e <- suppressMessages(esearch(db = "pubmed",
					term = term,
					mindate = as.character(mindate),
					maxdate = as.character(maxdate)
				))
		if (is.null(e$errors$wrnmsg)) {
			tbl.full <- efetch(e) |>
					content(as="xml") |>
					xmlToList() |>
					map_dfr(\(x) {
					  tibble(
						query = term,
						pmid = unlist(map(x, pluck, "PMID", "text")),
						# This modification is needed in case the title contains any italic or other formatted text; the pubmed record will divide the title into chunks for each format type
						title = paste(unlist(map(x, pluck, "Article", "ArticleTitle")),collapse=""), 
						journal =  unlist(map(x, pluck, "Article", "Journal", "Title")),
						pubdate = unlist(map(x, pluck, "Article", "Journal", "JournalIssue", "PubDate", "Year")),    
					  )
					})

			tbl.count <- tibble(Author1 = auth1_short,
				Author2 = auth2_short,
				n = length(tbl.full$pmid)
				)

			results_full <- bind_rows(results_full,tbl.full)
			results_counts <- bind_rows(results_counts,tbl.count)			
		} else {
			tbl.count <- tibble(Author1 = auth1_short,
					Author2 = auth2_short,
					n = 0
					)
			results_counts <- bind_rows(results_counts,tbl.count)
		}
	}	
}

# Write results
write_tsv(results_full,"CoPublication_table_full.txt")
write_tsv(results_counts,"CoPublication_table_counts.txt")

# Generate network plot
all_authors <- unique(c(results_counts$Author1,results_counts$Author2))

mat <- matrix(data=0,nrow=length(all_authors),ncol=length(all_authors))
rownames(mat) <- all_authors
colnames(mat) <- all_authors

for(i in 1:length(rownames(results_counts))) {
	mat[which(rownames(mat)==as.character(results_counts[i,1])),which(colnames(mat)==as.character(results_counts[i,2]))] = as.numeric(results_counts[i,3])
}

pdf("CoPublication_network.pdf",width=20,height=20)
qgraph(mat,
	layout="spring",
	directed=F,
	labels=rownames(mat),
	edge.color="black",
	curve=0,
	label.cex=3,
	label.scale.equal=T)
dev.off()

