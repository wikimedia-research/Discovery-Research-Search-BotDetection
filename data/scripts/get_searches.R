# Remotely:
message("Reading in base Hive query...")
query_base <- paste0(readLines("search_queries.hql"), collapse = "\n")

hql <- tempfile()

if (!dir.exists("tmp")) {
  dir.create("tmp")
}

# Run search_queries.hql for each day of the last N+1 days
n <- 0
dates <- seq(Sys.Date() - n - 1, Sys.Date() - 1, "day")
pb <- progress::progress_bar$new(total = length(dates))
for (i in 1:length(dates)) {
  # message("Fetching data from ", as.character(dates[i], format = "%Y-%m-%d"))
  pb$tick()
  # message("Constructing query...")
  query <- gsub("${DATE_CLAUSE}", wmf::date_clause(dates[i])$date_clause, query_base, fixed = TRUE)
  # Save it
  cat(query, file = hql, append = FALSE)
  # message("Running query in Hive...")
  system(paste0("export HADOOP_HEAPSIZE=1024 && hive -f ", hql, " > tmp/", as.character(dates[i], format = "%Y%m%d"), ".tsv"),
         ignore.stdout = n > 0, ignore.stderr = n > 0)
  # message("Finished getting the data...")
}; rm(i, dates, pb)

message("Cleaning up...")
invisible(file.remove(hql))

# Locally:
system("scp -r stat2:/home/bearloga/bot_detect/tmp/* data/raw/")
