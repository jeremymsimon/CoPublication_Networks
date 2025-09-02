# Overview
This repository contains code to generate co-publication networks in `R`. We perform pubmed searches using `reutils` between each author in the provided input list pairwise. The output of the script `FacultyCoPubSearchNetworks.R` contains a list of all resulting articles identified in the date range specified (`--minyear` and `--maxyear`), as well as the co-publication count for each author pair, and lastly a network graph drawn for all co-publications identified.

# Input
The input query author list (`.xlsx`, or tab-delimited text readable by `read_tsv`) has three columns:  
1) Author last name `<space>` Author first name
2) Author last name `<space>` Author first initial
3) Author primary affiliation (e.g. Dana-Farber Cancer Institute)

An example input query author list is as follows, here a list of highly-cited Cross-Field authors at UNC Chapel Hill:  
![image](https://user-images.githubusercontent.com/37712091/223880250-a15fee3f-f005-4dba-8c60-85c19689c417.png)


# Input parameters and example usage
```
Usage: Rscript FacultyCoPubSearchNetworks.R \
	-i highly_cited_UNC_testinput.xlsx \
	--minyear=2013 \
	--maxyear=2023 \
	-k abcdefg1234567

Options:
	-i FILENAME, --input=FILENAME
		Filename of input table containing faculty names
		Must be tab-delimited text or xlsx
			Column 1: AuthorLast AuthorFirst
			Column 2: AuthorLast AuthorFirstInitial
			Column 3: AuthorRole

	--minyear=MINYEAR
		Beginning year of date range for query (YYYY)

	--maxyear=MAXYEAR
		End year of date range for query (YYYY)

	-k APIKEY, --apikey=APIKEY
		Optional. NCBI API key for large queries, [default NULL]
		HIGHLY recommended, refer to E-utilities documentation here:
			https://www.ncbi.nlm.nih.gov/books/NBK25497/

	-h, --help
		Show this help message and exit
```

# Required R dependencies, note currently only tested in `R v4.1.0`
* `reutils`
* `XML`
* `tidyverse`
* `readxl`
* `optparse`
* `tools`
* `qgraph`

# Query performed
The pubmed query performed here searches for either instance of the author's names, in essence:  
`(author1 full name OR author1 first initial) AND (author2 full name OR author2 first initial)`

And further, is specific to the specified affiliation (provided as the 3rd column) such that the query includes this for each author's `[AFFL]`. This largely avoids issues 
where a given author name is not "pubmed unique". However, _author's names that are not unique to the given affiliation will return any and all matches_; thus some manual pruning of the output may be desired. 

Another consideration is when authors have multiple given or family names. Academic journals and pubmed do not handle these consistently! So if someone on my input list publishes under a name like "John Jacob Jingleheimer Schmidt", pubmed may list them as:
* Schmidt John
* Schmidt John Jacob
* Jingleheimer Schmidt John
* Jingleheimer Schmidt John Jacob

_plus lots of other possibilities_, so choose your input names wisely, and again manual pruning of the output may be desired for these cases. 


# Example Output
* [CoPublication_table_full.txt](CoPublication_table_full.txt)
  + Contains exact query as performed, followed by resulting pubmed ID, article title, journal, and publication year  
* [CoPublication_table_counts.txt](CoPublication_table_counts.txt)
  + Contains all pairwise author combinations and the resulting number of articles identified
* [CoPublication_network.pdf](CoPublication_network.pdf)
  + Co-publication network graph for all articles identified
 
**_Note: these tables will contain redundancies_**! `Author1:Author2` and `Author2:Author1` will of course return the same results and are not filtered. Moreover, articles that match more than two authors in the input list will show up in the results of each and every relevant pairwise query.

# Possible variations, modifications, and uses
* Run as-is on an entire list of department members to generate a co-publication network
* Modify to utilize author role to query faculty and trainee co-publications for a T32 proposal
	+ split `input_list` by role type and loop through each separately
* Remove the pairwise query aspect to find all publications by a single list of authors
* Other variations and tools have been constructed in the past by others, see:
	+ https://github.com/dkarneman/pubmetric
	+ https://ncstrategic.com/pubkeeper.html
