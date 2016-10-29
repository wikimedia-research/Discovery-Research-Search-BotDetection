The zero results rate (ZRR) -- proportion of searches that yield zero results -- is one of Discovery/Search team's KPIs. While we do have [an unrestricted API](https://www.mediawiki.org/wiki/API:Search_and_discovery) that anyone can use without an authentication key, automata still make up a lot of our web-based searches. And when we get hundreds of thousands of searches for things like '_qqqqqqq_', '_"^287adb56c9de9ad2f5b3b2c34f2ec339f74a5582c3c56c1b7e^pdefault c9b3c764-631c s4852e9" film_', and '_"downton abbey s1e7" film_' from user agents (UAs) that we have not yet added to our list of bot UAs, this inflates our ZRR, and, frankly, makes us look bad. The purpose of this project is to produce a classifier that can identify probable bots based on search queries and searching behavior patterns in addition to (rather than entirely based on) user-agent metadata. Once we can identify probable bots, we can try to have a clearer understanding of our zero results rate, focusing on human-made searches. See [T149440](https://phabricator.wikimedia.org/T149440) for more details.

-   [Repository Structure](#repository-structure)

Repository Structure
====================

-   [README.Rmd](README.Rmd) : generates README.md
-   [repo\_structure.yaml](repo_structure.yaml) : describes the structure of files and folders in this repository
-   [data/](data) : all data-related files and folders
    -   [scripts/](data/scripts) : scripts that build JARs, run queries, and process raw data
    -   [udfs/](data/udfs) : project-specific user-defined functions (UDFs) for using in Hive
        -   [source/](data/udfs/source) : Java class files
        -   [jars/](data/udfs/jars) : built JARs
    -   [queries/](data/queries) : HiveQL and SQL queries for extracting search logs and event logging data
    -   [raw/](data/raw) : for extracted data
    -   [processed/](data/processed) : for extracted data from raw/ that's been processed
