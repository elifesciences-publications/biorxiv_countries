---Authors per paper
SELECT article, EXTRACT(YEAR FROM observed), COUNT(id)
FROM prod.article_authors
WHERE observed IS NOT NULL
GROUP BY 1, 2
ORDER BY 2 ASC,3 DESC


---preprints per country (senior author)
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

--- preprints per country, any author
SELECT c.name, COUNT(DISTINCT aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
GROUP BY c.name
ORDER BY preprints DESC

--- preprints per country, complete-normalized counting
--- (each author given a fraction of 1 preprint)
SELECT c.name, SUM(1/cpa.authors::decimal) AS share
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
INNER JOIN ( --- authors per article
	SELECT article, COUNT(DISTINCT id) AS authors
	FROM prod.article_authors
	GROUP BY article
) AS cpa ON cpa.article=aa.article
GROUP BY c.name
ORDER BY share DESC

--- preprints per country, whole-normalized counting
--- (each COUNTRY given a fraction of 1 preprint)
SELECT article_points.country, SUM(article_points.share) AS points
FROM (
	SELECT DISTINCT ON (aa.article, c.name) aa.article, c.name AS country, 1/cpa.countries::decimal AS share
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.countries c ON i.country=c.alpha2
	INNER JOIN ( --- countries per article
		SELECT aa.article, COUNT(DISTINCT c.name) AS countries
		FROM prod.article_authors aa
		INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
		INNER JOIN prod.institutions i ON ai.institution=i.id
		INNER JOIN prod.countries c ON i.country=c.alpha2
		GROUP BY aa.article
	) AS cpa ON cpa.article=aa.article
) AS article_points
GROUP BY country
ORDER BY points DESC


---preprints per country, over time
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

--- Countries per preprint
SELECT aa.article, EXTRACT(year FROM aa.observed) AS year,
    COUNT(DISTINCT c.name) AS countries,
    COUNT(DISTINCT aa.id) AS authors
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
GROUP BY 1,2
ORDER BY countries DESC


--- preprints per institution (senior author)
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

--- preprints per institution, any author
SELECT i.id, i.name, COUNT(DISTINCT aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
GROUP BY 1,2
ORDER BY 3 DESC

--- international collaboration

-- papers with authors from multiple countries
SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
WHERE i.id > 0
GROUP BY aa.article
ORDER BY countrycount DESC


--- international collaborations, by country (senior author)
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

--- international collaborations by country (ONLY senior authors in the 'other' category)
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

--- international collaborations by country (any author in the 'other' category)
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
--- international collaborations, by country (any author)
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

--- International collaborations per institution
SELECT i.id, i.name, totalcount.preprints AS total, intlcount.preprints AS international, (intlcount.preprints/totalcount.preprints::decimal) AS proportion
FROM prod.institutions i
INNER JOIN (
    SELECT i.id, COUNT(aa.article) AS preprints
    FROM prod.article_authors aa
    INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
    INNER JOIN prod.institutions i ON ai.institution=i.id
    GROUP BY 1
) AS totalcount ON totalcount.id=i.id
INNER JOIN (
    SELECT i.id, COUNT(aa.article) AS preprints
    FROM prod.article_authors aa
    INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
    INNER JOIN prod.institutions i ON ai.institution=i.id
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
    )
    GROUP BY 1
) AS intlcount ON intlcount.id=i.id
WHERE totalcount.preprints >= 250
ORDER BY 3 DESC,4

--- combinations of contributor countries with senior authors
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

--- Senior-author count of UNIQUE papers featuring contributor countries
SELECT senior, COUNT(DISTINCT article)
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
GROUP BY 1
ORDER BY 2 DESC

--- Downloads per paper
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

--- published preprints from before 2019
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

--- publication rate by number of authors
SELECT countries, SUM(
	CASE WHEN doi IS NULL
	THEN 0
	ELSE 1
	END
) AS published,
COUNT(DISTINCT article) AS total
FROM (
	SELECT aa.article, EXTRACT(year FROM aa.observed) AS year, p.doi,
		COUNT(DISTINCT c.name) AS countries,
		COUNT(DISTINCT aa.id) AS authors
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.countries c ON i.country=c.alpha2
	LEFT JOIN prod.publications p ON aa.article=p.article
	GROUP BY 1,2,3
	ORDER BY countries DESC
) AS articlecounts
GROUP BY 1
ORDER BY 1 DESC

--- publication rate for international papers, by country
SELECT totals.country, totals.total, published.published
FROM (
    SELECT c.name AS country, COUNT(aa.article) AS total
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
    ORDER BY total DESC
) AS totals
INNER JOIN (
    SELECT c.name AS country, COUNT(aa.article) AS published
    FROM prod.article_authors aa
    INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
    INNER JOIN prod.institutions i ON ai.institution=i.id
    INNER JOIN prod.countries c ON i.country=c.alpha2
    INNER JOIN prod.publications p ON aa.article=p.article
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
    ORDER BY published DESC
) AS published ON totals.country=published.country
ORDER BY 3 DESC, 2 DESC


--- journal/country relationships in publications
SELECT c.name AS country, p.journal, COUNT(aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
INNER JOIN prod.publications p ON aa.article=p.article
WHERE aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
)
GROUP BY 1,2
ORDER BY 1,3 DESC

--- journal/institution relationships
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


--- journals per institution
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

--- STATEMENTS IN PAPER

---Total papers with authors
SELECT COUNT(DISTINCT article) FROM prod.article_authors;

----------------
--- ROR quality control
--- total author entries:
SELECT COUNT(affiliation) FROM prod.article_authors
--- unique:
SELECT COUNT(DISTINCT article) FROM prod.article_authors
SELECT COUNT(DISTINCT affiliation) FROM prod.article_authors

---unassigned affiliation strings, before correction:
SELECT COUNT(affiliation)
FROM prod.baseline_affiliation_institutions
WHERE institution=0
--- author entries with unassigned affiliation strings:
SELECT COUNT(aa.name)
FROM prod.article_authors aa
INNER JOIN prod.baseline_affiliation_institutions ai ON aa.affiliation=ai.affiliation
WHERE ai.institution=0

--- all the affiliation strings that changed institution
SELECT list.affiliation, a.name AS oldname, b.name AS newname
FROM (
    SELECT r.affiliation, b.institution AS old, r.institution AS new
    FROM prod.affiliation_institutions r
    INNER JOIN prod.baseline_affiliation_institutions b ON r.affiliation=b.affiliation
	WHERE r.institution > 0
) AS list
INNER JOIN prod.institutions a ON list.old=a.id
INNER JOIN prod.institutions b ON list.new=b.id
WHERE list.old != list.new

--- total authors affected by changes:
SELECT COUNT(id)
FROM prod.article_authors
WHERE affiliation IN (
	SELECT affiliation FROM (
		SELECT list.affiliation, a.name AS oldname, b.name AS newname
		FROM (
			SELECT r.affiliation, b.institution AS old, r.institution AS new
			FROM prod.affiliation_institutions r
			INNER JOIN prod.baseline_affiliation_institutions b ON r.affiliation=b.affiliation
		) AS list
		INNER JOIN prod.institutions a ON list.old=a.id
		INNER JOIN prod.institutions b ON list.new=b.id
		WHERE list.old != list.new
	) AS changed
)

---------
--- Precision/recall per country

--- Total strings per country, before correction:
SELECT i.country, COUNT(r.affiliation)
FROM prod.baseline_affiliation_institutions r
INNER JOIN prod.institutions i ON r.institution=i.id
GROUP BY 1
ORDER BY 2 DESC

--- Unchanged after correction
SELECT oldcountry, COUNT(newcountry)
FROM (
    SELECT list.affiliation, a.country AS oldcountry, b.country AS newcountry
    FROM (
        SELECT r.affiliation, b.institution AS old, r.institution AS new
        FROM prod.affiliation_institutions r
        INNER JOIN prod.baseline_affiliation_institutions b ON r.affiliation=b.affiliation
    ) AS list
    INNER JOIN prod.institutions a ON list.old=a.id
    INNER JOIN prod.institutions b ON list.new=b.id
) AS countrychanges
WHERE oldcountry != newcountry
GROUP BY 1
ORDER BY 2 DESC

--- Added
SELECT newcountry, COUNT(oldcountry)
FROM (
    SELECT list.affiliation, a.country AS oldcountry, b.country AS newcountry
    FROM (
        SELECT r.affiliation, b.institution AS old, r.institution AS new
        FROM prod.affiliation_institutions r
        INNER JOIN prod.baseline_affiliation_institutions b ON r.affiliation=b.affiliation
    ) AS list
    INNER JOIN prod.institutions a ON list.old=a.id
    INNER JOIN prod.institutions b ON list.new=b.id
) AS countrychanges
WHERE oldcountry != newcountry
GROUP BY 1
ORDER BY 2 DESC

--- Removed
SELECT oldcountry, COUNT(newcountry)
FROM (
    SELECT list.affiliation, a.country AS oldcountry, b.country AS newcountry
    FROM (
        SELECT r.affiliation, b.institution AS old, r.institution AS new
        FROM prod.affiliation_institutions r
        INNER JOIN prod.baseline_affiliation_institutions b ON r.affiliation=b.affiliation
    ) AS list
    INNER JOIN prod.institutions a ON list.old=a.id
    INNER JOIN prod.institutions b ON list.new=b.id
) AS countrychanges
WHERE oldcountry != newcountry
GROUP BY 1
ORDER BY 2 DESC

--- Looking at individual countries

--- Affiliations that changed countries in the corrections
SELECT affiliation, oldcountry
FROM (
    SELECT list.affiliation, a.country AS oldcountry, b.country AS newcountry
    FROM (
        SELECT r.affiliation, b.institution AS old, r.institution AS new
        FROM prod.affiliation_institutions r
        INNER JOIN prod.baseline_affiliation_institutions b ON r.affiliation=b.affiliation
    ) AS list
    INNER JOIN prod.institutions a ON list.old=a.id
    INNER JOIN prod.institutions b ON list.new=b.id
) AS countrychanges
WHERE oldcountry != newcountry
AND newcountry='CZ'

--- authors per affiliation
SELECT a.affiliation, COUNT(a.id)
FROM prod.article_authors a
WHERE a.affiliation IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC

--- Papers without any affiliation info for any authors
SELECT COUNT(article)
FROM (
	SELECT article, COUNT(affiliation)
	FROM prod.article_authors
	WHERE article IN (
		SELECT DISTINCT article
		FROM prod.article_authors
		WHERE affiliation='!!unknown!!'
	)
	GROUP BY 1 ORDER BY 2 ASC
) AS missingaff
WHERE count=1 --- if there's only 1 affiliation, it's '!!unknown!!'

--- Papers in which the first and last authors come from different countries
SELECT COUNT(DISTINCT first.article)
FROM (
	SELECT aa.article, c.name
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.countries c ON i.country=c.alpha2
	WHERE aa.id IN (
		SELECT MIN(id)
		FROM prod.article_authors
		GROUP BY article
	)
) AS first
INNER JOIN (
	SELECT aa.article, c.name
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.countries c ON i.country=c.alpha2
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM prod.article_authors
		GROUP BY article
	)
) AS last ON first.article=last.article
WHERE first.name != last.name
AND first.name != 'UNKNOWN'
AND last.name != 'UNKNOWN'

---Show senior author for all papers that include one author from country X
SELECT aa.article, aa.name, aa.affiliation, c.name
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
WHERE aa.article IN ( --- only show papers with at least one author from country X
	SELECT aa.article
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.countries c ON i.country=c.alpha2
	WHERE c.alpha2='BB'
) AND aa.id IN ( --- only show entry for senior author on each paper
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
) AND aa.article IN ( --- only show international papers
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
ORDER BY aa.id ASC

--- Looking for authors shared across publications published in a
--- single journal listing senior authors from a single university
SELECT name, COUNT(DISTINCT article)
FROM (
	SELECT *
	FROM prod.article_authors
	WHERE article IN (
		SELECT aa.article
		FROM prod.article_authors aa
		INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
		INNER JOIN prod.institutions i ON ai.institution=i.id
		INNER JOIN prod.publications p ON aa.article=p.article
		WHERE aa.id IN (
			SELECT MAX(id)
			FROM prod.article_authors
			GROUP BY article
		)
		AND i.name='University of Bristol'
		AND p.journal='International Journal of Epidemiology'
	)
	ORDER BY article, id
) AS asdf
GROUP BY 1
ORDER BY 2 DESC

---------------
--- AUTHOR INFORMATION

--- authors reporting affiliations in multiple countries
SELECT COUNT(author)
FROM (
	SELECT a.author, COUNT(DISTINCT i.country) AS countries
	FROM prod.author_institutions a
	INNER JOIN prod.institutions i ON a.institution=i.id
	GROUP BY a.author
) AS author_countries
WHERE author_countries.countries > 1

--- email suffix for University of California authors with no school
SELECT SUBSTRING(aa.email, '@.*\.(\w*).edu'), COUNT(aa.id)
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
WHERE ai.institution=10923
AND aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
)
GROUP BY 1
ORDER BY 2 DESC

--- preprints for which multiple authors share one ORCID
SELECT article, total, uniq, (total-uniq) AS copies
FROM (
	SELECT article, COUNT(orcid) AS total, COUNT(DISTINCT orcid) AS uniq
	FROM prod.article_authors
	GROUP BY 1
) AS counts
ORDER BY 4 DESC

---SAMPLE SIZE CALCULATION
--- get random sample of 100 to approximate population error rate:
SELECT DISTINCT a.affiliation, i.name, i.country, random() AS rand
FROM prod.article_authors a
INNER JOIN prod.affiliation_institutions lnk ON a.affiliation = lnk.affiliation
INNER JOIN prod.institutions i ON lnk.institution=i.id
WHERE lnk.institution > 0
ORDER BY rand
LIMIT 100;
