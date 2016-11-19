library(magrittr)
library(progress)

# Load extracted search queries:
datasets <- dir("data/raw", pattern = "*.tsv", full.names = TRUE)
search_queries <- do.call(rbind, lapply(datasets, read.delim, sep = "\t", as.is = TRUE, quote = ""))

# Fix the formatting of some variables:
search_queries$got_zero_results <- search_queries$got_zero_results == "true"
search_queries$is_bot <- search_queries$is_bot == "true"
search_queries$is_river_internet_reader <- search_queries$is_river_internet_reader == "true"
search_queries$accept_language[search_queries$accept_language == ""] <- NA

# Get country names from country codes:
data("ISO_3166_1", package = "ISOcodes")
ISO_3166_1 <- dplyr::rename(ISO_3166_1[, c("Alpha_2", "Name")], country_code = Alpha_2, country = Name)
search_queries <- dplyr::left_join(search_queries, ISO_3166_1, by = "country_code")

# Process Accept-Language data:
search_queries$primary_accept_language <- vapply(
  strsplit(search_queries$accept_language, ","),
  head, n = 1L, FUN.VALUE = "")
search_queries$language_code <- tolower(vapply(
  strsplit(search_queries$primary_accept_language, "-"),
  head, n = 1L, FUN.VALUE = ""))
search_queries$region_code <- toupper(vapply(
  strsplit(search_queries$primary_accept_language, "-"),
  function(x) { return(x[2]) }, FUN.VALUE = ""))
data("ISO_639_2", package = "ISOcodes")
ISO_639_2 <- dplyr::rename(ISO_639_2[, c("Alpha_2", "Name")], language_code = Alpha_2, language = Name)
ISO_3166_1 <- dplyr::rename(ISO_3166_1, region_code = country_code, language_region = country)
search_queries <- dplyr::left_join(search_queries, ISO_639_2, by = "language_code")
search_queries <- dplyr::left_join(search_queries, ISO_3166_1, by = "region_code")
# Impute regions
language_region_pairs <- search_queries %>%
  dplyr::filter(!is.na(language_region) & !is.na(language)) %>%
  dplyr::group_by(language, language_region) %>%
  dplyr::tally() %>%
  dplyr::top_n(1, n) %>%
  dplyr::ungroup()
pb <- progress_bar$new(total = sum(is.na(search_queries$language_region)))
search_queries$language_region[is.na(search_queries$language_region)] <- vapply(
  search_queries$language[is.na(search_queries$language_region)],
  function(language) {
    pb$tick()
    if (language %in% language_region_pairs$language) {
      return(language_region_pairs$language_region[language_region_pairs$language == language])
    } else {
      return(as.character(NA))
    }
  }, FUN.VALUE = ""
)
rm(pb)
# search_queries$language[is.na(search_queries$language)] <- "N/A"
# search_queries$language_region[is.na(search_queries$language_region)] <- "N/A"

# Clean up
search_queries$country_code <- NULL
search_queries$language_code <- NULL
search_queries$region_code <- NULL
search_queries$accept_language <- NULL
search_queries$primary_accept_language <- NULL

# Turn comma-separated arrays of features into an indicator matrix of 1s and 0s:
pb <- progress_bar$new(total = nrow(search_queries))
features_matrix <- search_queries$features %>%
  gsub("^\\[(.*)\\]$", "\\1", .) %>%
  strsplit(", ") %>%
  lapply(function(feats) {
    x <- rep(TRUE, length(feats))
    names(x) <- feats
    pb$tick()
    return(as.data.frame(t(x)))
  }) %>%
  do.call(dplyr::bind_rows, .) %>%
  lapply(function(column) {
    return(replace(column, is.na(column), FALSE))
  }) %>%
  dplyr::as_data_frame()
rm(pb)
