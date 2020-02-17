
---Authors per paper
SELECT article, EXTRACT(YEAR FROM observed), COUNT(id)
FROM prod.article_authors
GROUP BY 1, 2
ORDER BY 2 ASC,3 DESC


---preprints per country
SELECT i.country, COUNT(aa.article) AS preprints
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
WHERE aa.id IN (
	SELECT MAX(id)
	FROM prod.article_authors
	GROUP BY article
)
GROUP BY country
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

--- authors per affiliation
SELECT i.id, a.affiliation, COUNT(a.id)
FROM prod.article_authors a
GROUP BY 1,2
ORDER BY 3 DESC

---SAMPLE SIZE CALCULATION
--- get random sample of 100 to approximate population error rate:
SELECT DISTINCT a.affiliation, i.name, i.country, random() AS rand
FROM prod.article_authors a
INNER JOIN prod.affiliation_institutions lnk ON a.affiliation = lnk.affiliation
INNER JOIN prod.institutions i ON lnk.institution=i.id
WHERE lnk.institution > 0
ORDER BY rand
LIMIT 100;