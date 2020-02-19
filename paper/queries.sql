
---Authors per paper
SELECT article, EXTRACT(YEAR FROM observed), COUNT(id)
FROM prod.article_authors
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

--- preprints per country, any author
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

---SAMPLE SIZE CALCULATION
--- get random sample of 100 to approximate population error rate:
SELECT DISTINCT a.affiliation, i.name, i.country, random() AS rand
FROM prod.article_authors a
INNER JOIN prod.affiliation_institutions lnk ON a.affiliation = lnk.affiliation
INNER JOIN prod.institutions i ON lnk.institution=i.id
WHERE lnk.institution > 0
ORDER BY rand
LIMIT 100;

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

