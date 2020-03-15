# Data queries for figure source files

## Figure 1: Preprints per country

### 1a: Map of countries
```sql
SELECT i.country, COUNT(aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
WHERE aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
)
GROUP BY i.country
ORDER BY preprints DESC
```
(Saved in `preprints_country_all.csv`.)

### 1b: Preprints over time
```sql
WITH vars AS (
    SELECT 8::integer AS maxcountries
), senior_authors AS (
    SELECT article, MAX(id) AS id
    FROM prod.article_authors
    GROUP BY 1
), top_countries AS (
    SELECT countries.name, COUNT(aa.article) AS preprints
    FROM prod.article_authors aa
    INNER JOIN prod.affiliation_institutions ai
        ON ai.affiliation=aa.affiliation
    INNER JOIN prod.institutions
        ON institutions.id=ai.institution
    INNER JOIN prod.countries
        ON institutions.country=countries.alpha2
    WHERE aa.id IN (SELECT id FROM senior_authors)
    GROUP BY 1
    ORDER BY 2 DESC
), monthly_totals AS (
    SELECT EXTRACT(YEAR FROM aa.observed)||'-'||lpad(EXTRACT(MONTH FROM aa.observed)::text, 2, '0') AS month,
    countries.name AS country,
    COUNT(aa.article) AS month_total
    FROM prod.article_authors aa
    INNER JOIN prod.affiliation_institutions ai
        ON ai.affiliation=aa.affiliation
    INNER JOIN prod.institutions
        ON institutions.id=ai.institution
    INNER JOIN prod.countries
        ON countries.alpha2=institutions.country
    WHERE aa.id IN (SELECT id FROM senior_authors)
    GROUP BY month, countries.name
)
SELECT month, country, month_total,
		SUM (month_total) OVER (PARTITION BY country ORDER BY month) AS running_total
FROM monthly_totals
WHERE country IN (    --- figure out which countries are the top ones, and only grab those
	SELECT name FROM top_countries
	LIMIT (SELECT maxcountries FROM vars)
)
UNION   --- After totals for top countries, add in the "other" category
SELECT month, country, month_total,
	SUM (month_total) OVER (ORDER BY month) AS running_total
FROM (
	SELECT month, country, SUM(month_total) AS month_total
	FROM (
		SELECT month, 'OTHER'::text as country, month_total
		FROM monthly_totals
		WHERE country NOT IN (  --- Don't count the top countries in the "other" category
			SELECT name FROM top_countries
			LIMIT (SELECT maxcountries FROM vars)
		)
		ORDER BY month ASC
	) AS excluded_country_totals
	GROUP BY month, country
	ORDER BY month ASC
) AS excluded_countries_combined
ORDER BY month ASC, country ASC
```
(Saved in `preprints_country_time.csv`.)

### 1c: Preprints per country total

See Fig. 1a.

### 1d: Senior author rate, international preprints

See Fig. *tk.

International collaborations by senior author, countries in "other" category:

```sql
SELECT c.name, COUNT(aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
WHERE aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
) AND aa.article IN (
    SELECT DISTINCT article
    FROM (
        SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
        FROM prod.article_authors aa
        INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
        INNER JOIN prod.institutions i ON ai.institution=i.id
        INNER JOIN prod.countries c ON i.country=c.alpha2
        WHERE i.id > 0
        GROUP BY aa.article
        ORDER BY countrycount DESC
    ) AS countrz
    WHERE countrycount >= 2
) AND c.name NOT IN (
    SELECT name FROM (
        SELECT countries.name, COUNT(aa.article) AS preprints
        FROM prod.article_authors aa
        INNER JOIN prod.affiliation_institutions ai
            ON ai.affiliation=aa.affiliation
        INNER JOIN prod.institutions
            ON institutions.id=ai.institution
        INNER JOIN prod.countries
            ON institutions.country=countries.alpha2
        WHERE aa.id IN (
            SELECT id FROM (
                SELECT article, MAX(id) AS id
                FROM prod.article_authors
                GROUP BY 1
            ) AS seniorauthors
        )
        GROUP BY 1
        ORDER BY 2 DESC
    ) AS preprints
    LIMIT 8
)
GROUP BY c.name
ORDER BY preprints DESC
```

International collaborations by senior author, countries in "other" category:

```sql
SELECT COUNT(DISTINCT aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
WHERE aa.article IN (
    SELECT DISTINCT article
    FROM (
        SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
        FROM prod.article_authors aa
        INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
        INNER JOIN prod.institutions i ON ai.institution=i.id
        INNER JOIN prod.countries c ON i.country=c.alpha2
        WHERE i.id > 0
        GROUP BY aa.article
        ORDER BY countrycount DESC
    ) AS countrz
    WHERE countrycount >= 2
) AND c.name NOT IN (
    SELECT name FROM (
        SELECT countries.name, COUNT(aa.article) AS preprints
        FROM prod.article_authors aa
        INNER JOIN prod.affiliation_institutions ai
            ON ai.affiliation=aa.affiliation
        INNER JOIN prod.institutions
            ON institutions.id=ai.institution
        INNER JOIN prod.countries
            ON institutions.country=countries.alpha2
        WHERE aa.id IN (
            SELECT id FROM (
                SELECT article, MAX(id) AS id
                FROM prod.article_authors
                GROUP BY 1
            ) AS seniorauthors
        )
        GROUP BY 1
        ORDER BY 2 DESC
    ) AS preprints
    LIMIT 8
)
```



## Figure 3: Preprints per institution

Senior author:

```sql
SELECT i.id, i.name, COUNT(aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
WHERE aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
)
GROUP BY 1,2
ORDER BY 3 DESC
```

Any author:

```sql
SELECT i.id, i.name, COUNT(DISTINCT aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
GROUP BY 1,2
ORDER BY 3 DESC
```

(Saved in `preprints_per_institution.csv`.)



## Figure 4: Collaboration

### 4a: Authors per preprint

```sql
SELECT article, EXTRACT(YEAR FROM observed), COUNT(id)
FROM prod.article_authors
WHERE observed IS NOT NULL
GROUP BY 1, 2
ORDER BY 2 ASC,3 DESC
```

(Saved in `authors_per_paper.csv`.)

### 4b: Countries per preprint over time

```sql
SELECT aa.article, EXTRACT(year FROM aa.observed) AS year,
    COUNT(DISTINCT c.name) AS countries,
    COUNT(DISTINCT aa.id) AS authors
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
GROUP BY 1,2
ORDER BY countries DESC
```

(Saved in `countries_per_paper.csv`.)

### 4c: Countries per preprint

See Fig. 4b.



## Figure 5: Contributor countries

### 5c: Senior authors with contributor countries

Combinations of contributor countries with senior authors:
```sql
SELECT contributor, senior, COUNT(DISTINCT article)
FROM (
	SELECT DISTINCT ON (aa.article, c.name) aa.article, c.name AS contributor, seniors.country AS senior
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.countries c ON i.country=c.alpha2
	LEFT JOIN (
		SELECT aa.article, c.name AS country
		FROM prod.article_authors aa
		INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
		INNER JOIN prod.institutions i ON ai.institution=i.id
		INNER JOIN prod.countries c ON i.country=c.alpha2
		WHERE aa.id IN ( --- only show entry for senior author on each paper
			SELECT MAX(id)
			FROM prod.article_authors
			GROUP BY article
		) AND ---exclude the senior-author papers from contributor countries
		c.alpha2 NOT IN ('UG', 'TZ', 'VN', 'HR', 'SK', 'ID', 'TH', 'GR', 'KE', 'BD', 'EG', 'EC', 'EE', 'PE', 'TR', 'BO', 'CZ', 'CO', 'IS')
	) AS seniors ON aa.article=seniors.article
	WHERE aa.article IN ( --- only show international papers
		SELECT DISTINCT article
		FROM (
			SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
			FROM prod.article_authors aa
			INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
			INNER JOIN prod.institutions i ON ai.institution=i.id
			INNER JOIN prod.countries c ON i.country=c.alpha2
			WHERE i.id > 0
			GROUP BY aa.article
			ORDER BY countrycount DESC
		) AS countrz
		WHERE countrycount >= 2
	) AND aa.id IN ( --- list all entries for authors from contributor countries
		SELECT aa.id
		FROM prod.article_authors aa
		INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
		INNER JOIN prod.institutions i ON ai.institution=i.id
		INNER JOIN prod.countries c ON i.country=c.alpha2
		WHERE c.alpha2 IN ('UG', 'TZ', 'VN', 'HR', 'SK', 'ID', 'TH', 'GR', 'KE', 'BD', 'EG', 'EC', 'EE', 'PE', 'TR', 'BO', 'CZ', 'CO', 'IS')
	)
) AS intntl
WHERE senior IS NOT NULL
GROUP BY 1,2
```

(Saved in `contributor_country_senior_counts.csv`)



## Figure 6

### 6a: Downloads per preprint

```sql
SELECT aa.article, EXTRACT(year FROM aa.observed) AS year,
	dloads.downloads,
	seniors.name AS country,
    COUNT(DISTINCT c.name) AS countries,
    COUNT(DISTINCT aa.id) AS authors
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
INNER JOIN (
	SELECT article, SUM(pdf) AS downloads
	FROM prod.article_traffic
	GROUP BY 1
) AS dloads ON aa.article=dloads.article
INNER JOIN (
	SELECT c.name, aa.article
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.countries c ON i.country=c.alpha2
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM prod.article_authors
		GROUP BY article
	)
) AS seniors ON seniors.article=aa.article
GROUP BY 1,2,3,4
ORDER BY dloads.downloads DESC
```

(Saved in `downloads_per_paper.csv`.)

### 6d: Publication rate by country

Published preprints by country:

```sql
SELECT c.name, COUNT(aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
INNER JOIN prod.publications p ON aa.article=p.article
WHERE aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
) AND
EXTRACT(year FROM aa.observed) < 2019 
GROUP BY c.name
ORDER BY preprints DESC
```

(Saved in `overview_by_country.csv`.)


## Table 1: Preprints per country

Senior author:

```sql
SELECT c.name, COUNT(aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
WHERE aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
)
GROUP BY c.name
ORDER BY preprints DESC
```

Any author:

```sql
SELECT c.name, COUNT(DISTINCT aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
GROUP BY c.name
ORDER BY preprints DESC
```
(Saved in `overview_by_country.csv`.)



## Table 2: Contributor countries

International collaborations by country (senior author):

```sql
SELECT c.name, COUNT(aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
WHERE aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
) AND aa.article IN (
    SELECT DISTINCT article
    FROM (
        SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
        FROM prod.article_authors aa
        INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
        INNER JOIN prod.institutions i ON ai.institution=i.id
        INNER JOIN prod.countries c ON i.country=c.alpha2
        WHERE i.id > 0
        GROUP BY aa.article
        ORDER BY countrycount DESC
    ) AS countrz
    WHERE countrycount >= 2
)
GROUP BY c.name
ORDER BY preprints DESC
```

International collaborations by country (any author):

```sql
SELECT c.name, COUNT(DISTINCT aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
WHERE aa.article IN (
    SELECT DISTINCT article
    FROM (
        SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
        FROM prod.article_authors aa
        INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
        INNER JOIN prod.institutions i ON ai.institution=i.id
        INNER JOIN prod.countries c ON i.country=c.alpha2
        WHERE i.id > 0
        GROUP BY aa.article
        ORDER BY countrycount DESC
    ) AS countrz
    WHERE countrycount >= 2
)
GROUP BY c.name
ORDER BY preprints DESC
```

(Saved in `overview_by_country.csv`.)



## Table 3: Journal–institution links

```sql
SELECT published.institution, published.journal, published.total AS published, totals.total AS institution_total,
	(published.total / totals.total::decimal) AS i_proportion,
	journaltotal.total AS journal_total, (published.total / journaltotal.total::decimal) AS j_proportion
FROM (
	SELECT i.name AS institution, p.journal, COUNT(aa.article) AS total
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.publications p ON aa.article=p.article
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM prod.article_authors
		GROUP BY article
	)
	GROUP BY 1,2
) AS published
LEFT JOIN (
	SELECT i.name AS institution, COUNT(aa.article) AS total
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM prod.article_authors
		GROUP BY article
	)
	GROUP BY 1
) AS totals ON published.institution=totals.institution
LEFT JOIN (
	SELECT p.journal, COUNT(aa.article) AS total
	FROM prod.article_authors aa
	INNER JOIN prod.publications p ON aa.article=p.article
	GROUP BY 1
) AS journaltotal ON published.journal=journaltotal.journal
```

(Saved in `publication_journal_institution.csv`.)



## Table 4: Preprints per journal

```sql
SELECT published.institution, published.total AS preprints, journalcounts.jcount AS journals
FROM (
	SELECT i.name AS institution, COUNT(aa.article) AS total
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.publications p ON aa.article=p.article
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM prod.article_authors
		GROUP BY article
	)
	GROUP BY 1
) AS published
INNER JOIN (
	SELECT i.name AS institution, COUNT(DISTINCT p.journal) AS jcount
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.publications p ON aa.article=p.article
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM prod.article_authors
		GROUP BY article
	)
	GROUP BY 1
) AS journalcounts ON journalcounts.institution=published.institution
```

(Saved in `preprints_per_journal_institution.csv`.)
