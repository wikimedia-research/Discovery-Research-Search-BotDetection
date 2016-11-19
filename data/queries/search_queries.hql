SET sample_rate=0.01;

ADD JAR hdfs:///wmf/refinery/current/artifacts/refinery-hive.jar;
CREATE TEMPORARY FUNCTION ua_parser AS 'org.wikimedia.analytics.refinery.hive.UAParserUDF';
CREATE TEMPORARY FUNCTION is_spider AS 'org.wikimedia.analytics.refinery.hive.IsSpiderUDF';
CREATE TEMPORARY FUNCTION array_sum AS 'org.wikimedia.analytics.refinery.hive.ArraySumUDF';
CREATE TEMPORARY FUNCTION geocode_country as 'org.wikimedia.analytics.refinery.hive.GeocodedCountryUDF';
CREATE TEMPORARY FUNCTION deconstruct AS 'org.wikimedia.analytics.refinery.hive.DeconstructSearchQueryUDF';

USE wmf_raw;
SELECT
  `timestamp`, refined_searches.uid AS uid, wiki_searched,
  query, features, got_zero_results,
  device, os, browser,
  country_code, accept_language,
  is_bot, is_river_internet_reader
FROM (
  SELECT
    FROM_UNIXTIME(ts) AS `timestamp`,
    CONCAT(useragent, ' from ', ip) AS uid,
    wikiid AS wiki_searched,
    REGEXP_REPLACE(TRIM(LOWER(requests.query[SIZE(requests.query)-1])), '\\t', ' ') AS query,
    deconstruct(REGEXP_REPLACE(TRIM(LOWER(requests.query[SIZE(requests.query)-1])), '\\t', ' ')) AS features,
    array_sum(requests.hitstotal, -1) = 0 AS got_zero_results,
    ua_parser(useragent)['device_family'] AS device,
    ua_parser(useragent)['os_family'] AS os,
    ua_parser(useragent)['browser_family'] AS browser,
    geocode_country(ip) AS country_code,
    payload['acceptLang'] AS accept_language,
    (
      ua_parser(useragent)['device_family'] = 'Spider'
      OR is_spider(useragent)
      OR ip = '127.0.0.1'
      OR (
        ua_parser(useragent)['device_family'] = 'Other'
        AND ua_parser(useragent)['os_family'] = 'Other'
        AND ua_parser(useragent)['browser_family'] = 'Other'
      )
      OR INSTR(useragent , 'Automat') > 0
      OR INSTR(useragent, 'J. River Internet Reader') > 0 -- searches things like: "mr robot s1e3" film
    ) AS is_bot,
    INSTR(useragent, 'J. River Internet Reader') > 0 AS is_river_internet_reader
  FROM CirrusSearchRequestSet
  ${DATE_CLAUSE}
    AND source = 'web' AND SIZE(backendusertests) = 0
    AND requests[size(requests)-1].querytype = 'full_text'
) refined_searches
RIGHT JOIN (
  SELECT uid, RAND() AS sample_key
  FROM (
    SELECT DISTINCT CONCAT(useragent, ' from ', ip) AS uid
    FROM CirrusSearchRequestSet
    ${DATE_CLAUSE}
      AND source = 'web' AND SIZE(backendusertests) = 0
      AND requests[size(requests)-1].querytype = 'full_text'
  ) AS user_ids
) sampled_ids
ON sampled_ids.uid = refined_searches.uid
WHERE sample_key <= '${hiveconf:sample_rate}';
