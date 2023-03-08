library(reutils)
library(tidyverse)
library(XML)
library(readxl)

mindate <- 2013
maxdate <- 2023

input_list <- read_excel("NBIO_curriculum_faculty_list_2023-03-08.xlsx",col_names=c("Full","Short","Title"))

results_full <- c()
results_counts <- c()

for(i in 1:length(input_list$Full)) {
	for(j in 1:length(input_list$Full)) {
		if(i==j) next
	   	# Incorporate sleeps to slow down queries and avoid error about too many requests
	   	if(i %% 2 == 0 || j %% 2 == 0) {
			Sys.sleep(10)
		}
		
		auth1_full <- as.character(input_list[i,"Full"])
		auth2_full <- as.character(input_list[j,"Full"])
		auth1_short <- as.character(input_list[i,"Short"])
		auth2_short <- as.character(input_list[j,"Short"])

		term <- paste0("(",auth1_full, " [AUTH] University of North Carolina [AFFL] OR ",auth1_short," [AUTH] University of North Carolina [AFFL]) AND (",auth2_full, " [AUTH] University of North Carolina [AFFL] OR ",auth2_short," [AUTH] University of North Carolina [AFFL])")
		print(term)
		e <- suppressMessages(esearch(db = "pubmed",
					term = term,
					mindate=mindate,
					maxdate=maxdate
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

write_tsv(results_full,"NBIO_curriculum_faculty_list_2023-03-08_coPublication_table_full.txt")
write_tsv(results_counts,"NBIO_curriculum_faculty_list_2023-03-08_coPublication_table_counts.txt")
