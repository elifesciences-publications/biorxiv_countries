# Trends in country-level authorship and collaboration in bioRxiv preprints
By RJ Abdill, EM Adamowicz, R Blekhman

The code below documents two sets of scripts: SQL queries are used to extract information from the database into CSV files, and R snippets are used for analysis and all figures. All code appears approximately in the order the data appears in the manuscript.

## Configuration
Setting up SQL parameters:
```sql
SET search_path TO prod;
```

Setting up R session:
```r
library(ggplot2)
library(cowplot) # for combining figures
library(patchwork)
require(scales) # for axis labels
library(grid)
library(RColorBrewer)# for pretty
library(tidyr) # for gather()
library(ggalluvial) # for alluvial plot

library(dplyr) # for top_n
library(DescTools) # for harmonic mean

library(rworldmap) # for map of preprints

themedarktext = "#707070"
big_fontsize = unit(12, "pt")
basetheme <- theme(
  axis.text.x = element_text(size=big_fontsize, color = themedarktext),
  axis.text.y = element_text(size=big_fontsize, color = themedarktext),
  axis.title.x = element_text(size=big_fontsize, color = themedarktext),
  axis.title.y = element_text(size=big_fontsize, color = themedarktext),
  legend.text = element_text(size=big_fontsize, color = themedarktext),
)

add_year_x <- function(plot, labels, yearlabel)
{
  # Adds an x axis with delineations and labels for each year.
  # plot: a ggplot object
  # labels: BOOLEAN indicating whether to add labels for each year
  # yearlabel: INT value indicating where on the y-axis the year labels should fall.
  yearline = "black"
  yearline_size = 0.5
  yearline_alpha = 1
  yearline_2014 = 8 # position of first year label
  x <- plot +
    geom_vline(xintercept=2.5, col=yearline, size=yearline_size, alpha=yearline_alpha) +
    
    geom_vline(xintercept=14.5, col=yearline, size=yearline_size, alpha=yearline_alpha) +
    geom_vline(xintercept=26.5, col=yearline, size=yearline_size, alpha=yearline_alpha) +
    geom_vline(xintercept=38.5, col=yearline, size=yearline_size, alpha=yearline_alpha) +
    geom_vline(xintercept=50.5, col=yearline, size=yearline_size, alpha=yearline_alpha) +
    geom_vline(xintercept=62.5, col=yearline, size=yearline_size, alpha=yearline_alpha)
  
  if(labels) {
    x <- x +
      annotation_custom(
        grob = textGrob(label = "2014", hjust = 0.5, vjust=1, gp = gpar(fontsize = big_fontsize, col=themedarktext)),
        ymin = yearlabel, ymax = yearlabel, xmin = yearline_2014, xmax = yearline_2014) +
      annotation_custom(
        grob = textGrob(label = "2015", hjust = 0.5, vjust=1, gp = gpar(fontsize = big_fontsize, col=themedarktext)),
        ymin = yearlabel, ymax = yearlabel, xmin = yearline_2014+12, xmax = yearline_2014+12) +
      annotation_custom(
        grob = textGrob(label = "2016", hjust = 0.5, vjust=1, gp = gpar(fontsize = big_fontsize, col=themedarktext)),
        ymin = yearlabel, ymax = yearlabel, xmin = yearline_2014 + 24, xmax = yearline_2014 + 24) +
      annotation_custom(
        grob = textGrob(label = "2017", hjust = 0.5, vjust=1, gp = gpar(fontsize = big_fontsize, col=themedarktext)),
        ymin = yearlabel, ymax = yearlabel, xmin = yearline_2014 + 36, xmax = yearline_2014 + 36) +
      annotation_custom(
        grob = textGrob(label = "2018", hjust = 0.5, vjust=1, gp = gpar(fontsize = big_fontsize, col=themedarktext)),
        ymin = yearlabel, ymax = yearlabel, xmin = yearline_2014 + 48, xmax = yearline_2014 + 48) +
      annotation_custom(
        grob = textGrob(label = "2019", hjust = 0.5, vjust=1, gp = gpar(fontsize = big_fontsize, col=themedarktext)),
        ymin = yearlabel, ymax = yearlabel, xmin = yearline_2014 + 60, xmax = yearline_2014 + 60)
  }
  return(x)
}

cleanup_countries <- function(matrix) {
  # converts lengthy country names to shorter versions. accepts a data frame and manipulates the "country" field before returning it.
  matrix$country <- as.character(matrix$country)
  matrix$country[matrix$country=='United States of America'] <- 'United States'
  matrix$country[matrix$country=='United Kingdom of Great Britain and Northern Ireland'] <- 'United Kingdom'
  matrix$country[matrix$country=='Korea, Republic of'] <- 'South Korea'
  matrix$country[matrix$country=='Taiwan, Province of China'] <- 'Taiwan'
  matrix$country[matrix$country=='Iran (Islamic Republic of),'] <- 'Iran'
  matrix$country[matrix$country=='Russian Federation'] <- 'Russia'
  matrix$country <- as.factor(matrix$country)
  return(matrix)
}
```

## 2. Results
### 2.1 Preprint origins
Total preprints in analysis:
```sql
SELECT COUNT(DISTINCT article) FROM article_authors;
```

#### Table 1: Preprints per country
(Truncated list appears as Table 1; full list appears as **Supplementary Table 1**.)
```sql
SELECT anyauthor.alpha2, anyauthor.country, COALESCE(seniorauthor.preprints, 0) AS senior_author, anyauthor.preprints AS any_author
FROM (
	SELECT c.name AS country, c.alpha2 AS alpha2, COUNT(DISTINCT aa.article) AS preprints
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	GROUP BY 1,2
) AS anyauthor
LEFT JOIN (
	SELECT c.name AS country, COUNT(aa.article) AS preprints
	FROM prod.article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM article_authors
		GROUP BY article
	)
	GROUP BY c.name
) AS seniorauthor ON anyauthor.country=seniorauthor.country
ORDER BY senior_author DESC, any_author DESC
```

### Figure 1: Preprints per country

#### Figure 1a: World map
Uses same data as Table 1. Plotting map:
```r
data <- read.csv('supp_table01.csv', header = TRUE, stringsAsFactors = FALSE) %>%
  dplyr::select(alpha2, senior_author)
colnames(data) <- c('country','value')
toplot <- joinCountryData2Map(data, joinCode = "ISO2",
                              nameJoinColumn = "country",  mapResolution = "coarse", verbose=TRUE)

# chop off antarctica
toplot <- subset(toplot, continent != "Antarctica")

map <- mapCountryData(toplot, nameColumnToPlot = "value",
  catMethod = "logFixedWidth", numCats=6,
  xlim = NA, ylim = NA, mapRegion = "world",
  colourPalette = "heat", addLegend = FALSE, borderCol = "grey",
  mapTitle = "",
  oceanCol = NA, aspect = 1,
  missingCountryCol = NA, add = FALSE,
  lwd = 0.5)

x <- do.call(
  addMapLegend,
  c( map, legendLabels="all",
     horizontal=FALSE,
     legendShrink = 0.3,
     legendIntervals='page',
     legendMar=60, # move it closer to the continents
     legendWidth=0.7,
     labelFontSize=0.85,
     digits=1
     #tcl=-1.2 # tick mark
  )
)
```
Panel 1a is the only figure panel not arranged in R—it was exported separately and joined with the rest of the figure afterward.



#### Figure 1b: Preprints per country over time
Data saved as `preprints_over_time.csv`. One aspect was modified by hand: Countries in this query only have entries in months for which they posted new preprints, so in the early months, some countries are missing (i.e. Australia had no preprints in a month early in 2014, so that bar segment disappears in that month). These were added manually.
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

Building the panel:

```r
monthframe=read.csv('preprints_over_time.csv')
labelx <- 76
labelsize <- unit(10, "pt")
time <- ggplot(monthframe, aes(x=month, y=running_total,
                               group=country, color=country, fill=country)) +
  geom_bar(position="fill", stat="identity") +
  labs(x = "", y = "Cumulative preprints") +
  scale_y_continuous(expand=c(0,0)) +
  theme_bw() +
  scale_fill_brewer(palette = 'Set1', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    axis.text.x=element_blank(),
    axis.text.y=element_blank(),
    legend.position="none",
    plot.margin = unit(c(1,6,1,1), "lines"), # for right-margin labels
  ) +
  annotation_custom(
    grob = textGrob(label = "UNKNOWN", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.07, ymax = 0.07, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "United States", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.35, ymax = 0.35, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "United Kingdom", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.57, ymax = 0.57, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "OTHER", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.72, ymax = 0.72, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "Germany", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.85, ymax = 0.85, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "France", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.89, ymax = 0.89, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "China", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.93, ymax = 0.93, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "Canada", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.965, ymax = 0.965, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "Australia", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 1.0, ymax = 1.0, xmin = labelx, xmax = labelx)

time <- add_year_x(time, TRUE, -0.03)
time <- ggplot_gtable(ggplot_build(time))
time$layout$clip[time$layout$name == "panel"] <- "off"
```

#### Figure 1c: Preprints per country, senior author
Uses the same data as Figure 1b. Building the panel:

```r
data <- monthframe[monthframe$month=='2019-12',]

senior <- ggplot(
  data=data,
  aes(x=reorder(country, running_total), y=running_total, fill=country)
) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0), breaks=seq(0,30000,8000), labels=comma) +
  coord_flip(ylim=c(0,28000)) +
  labs(x = "Country", y = "Preprints, senior author") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set1', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = "none"
  )
```

#### Figure 1d: Preprints per country, any author
Uses the same data as Table 1, with an additional "OTHER" total pulled from this query:

```sql
SELECT COUNT(DISTINCT aa.article)
FROM prod.article_authors aa
INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN prod.institutions i ON ai.institution=i.id
INNER JOIN prod.countries c ON i.country=c.alpha2
WHERE c.name NOT IN (
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

Building the panel:

```r
data <- read.csv('supp_table01.csv')
data <- cleanup_countries(data[1:8,])
data$country <- as.character(data$country)
data <- rbind(data, data.frame(alpha2=NA, country='OTHER',senior_author=10000,any_author=25347)) # dummy value for "senior author"
data$country <- as.factor(data$country)

any <- ggplot(
  data=data,
  aes(x=reorder(country, senior_author), y=any_author, fill=country)
) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0), breaks=seq(0,36000,8000), labels=comma) +
  coord_flip(ylim=c(0,36000)) +
  labs(x = "Country", y = "Preprints, any author") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set1', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.title.y = element_blank()
  )
```

#### Compiling Figure 1
```r
plot_grid(time,
  plot_grid(senior, any, nrow=1,ncol=2, rel_widths=c(3,2),
            labels=c('c','d'), hjust = c(-0.65, 0.5), vjust=c(0.5, 0.5)
  ),
  ncol=1, nrow=2, rel_heights=c(3,2), labels=c('b'))
```
