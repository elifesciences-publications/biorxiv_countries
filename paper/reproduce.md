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
library(ggrepel) # for the labeled scatter plot

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

## Results: Preprint origins
Total preprints in analysis:
```sql
SELECT COUNT(DISTINCT article) FROM article_authors;
```

### Table 1: Preprints per country
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
	FROM article_authors aa
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
    FROM article_authors
    GROUP BY 1
), top_countries AS (
    SELECT countries.name, COUNT(aa.article) AS preprints
    FROM article_authors aa
    INNER JOIN affiliation_institutions ai
        ON ai.affiliation=aa.affiliation
    INNER JOIN institutions
        ON institutions.id=ai.institution
    INNER JOIN countries
        ON institutions.country=countries.alpha2
    WHERE aa.id IN (SELECT id FROM senior_authors)
    GROUP BY 1
    ORDER BY 2 DESC
), monthly_totals AS (
    SELECT EXTRACT(YEAR FROM aa.observed)||'-'||lpad(EXTRACT(MONTH FROM aa.observed)::text, 2, '0') AS month,
    countries.name AS country,
    COUNT(aa.article) AS month_total
    FROM article_authors aa
    INNER JOIN affiliation_institutions ai
        ON ai.affiliation=aa.affiliation
    INNER JOIN institutions
        ON institutions.id=ai.institution
    INNER JOIN countries
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
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN institutions i ON ai.institution=i.id
INNER JOIN countries c ON i.country=c.alpha2
WHERE c.name NOT IN (
    SELECT name FROM (
        SELECT countries.name, COUNT(aa.article) AS preprints
        FROM article_authors aa
        INNER JOIN affiliation_institutions ai
            ON ai.affiliation=aa.affiliation
        INNER JOIN institutions
            ON institutions.id=ai.institution
        INNER JOIN countries
            ON institutions.country=countries.alpha2
        WHERE aa.id IN (
            SELECT id FROM (
                SELECT article, MAX(id) AS id
                FROM article_authors
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


### Figure 2: Preprint enthusiasm

Data for all panels in this figure are available in **Supplementary Table 2**, which was compiled by adding the senior-author totals from Supplementary Table 1 to data scraped from Scimago. Loading the dataset and calculating the proportions:
```r
data <- read.csv('supp_table02.csv')
data <- data[data$senior_author_preprints>50,]
data <- cleanup_countries(data)
data$country <- as.character(data$country) 
data[data$country=='United States',]$country <- 'USA'
data[data$country=='United Kingdom',]$country <- 'UK'
data$country <- as.factor(data$country)

data$prop_citable <- data$citable_total / sum(data$citable_total)
data$prop_preprint <- data$senior_author_preprints / 67885
data$enthusiasm <- data$prop_preprint / data$prop_citable
# NOTE: We don't use a live sum of the preprints because this table
# excludes 9000+ "UNKNOWN" preprints
```

#### Figure 2a: Preprint enthusiasm by total citable documents
```r
scatter <- ggplot(data) +
  geom_point(aes(x=citable_total, y=enthusiasm)) +
  geom_hline(yintercept=1, color='red', size=0.2) +
  geom_text_repel(
    aes(x=citable_total, y=enthusiasm, label=country),
    size=4,
    segment.size = 0.5,
    segment.color = "grey50",
    point.padding = 0.2,
    max.iter = 5000
  ) +
  scale_x_log10(labels=comma) +
  scale_size_continuous(name='Preprints,\nsenior author', labels=comma) +
  labs(x='Citable documents', y='bioRxiv enthusiasm') +
  theme_bw() +
  basetheme
```

#### Figure 2b: Top preprint enthusiasm
```r
enthusiasm_top <- ggplot(data=data[1:10,], aes(x=reorder(country, enthusiasm), y=enthusiasm)) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0)) +
  coord_flip(ylim=c(0,2.8)) +
  labs(x = "Country", y = "bioRxiv enthusiasm") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set2', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    plot.margin = margin(0,0,0,0)
  )
```

#### Figure 2c: Bottom preprint enthusiasm
```r
enthusiasm_bottom <- ggplot(data=data[35:44,], aes(x=reorder(country, enthusiasm), y=enthusiasm)) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0)) +
  coord_flip(ylim=c(0,2.8)) +
  labs(x = "Country", y = "bioRxiv enthusiasm") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set2', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    plot.margin = margin(0,0,0,0)
  )
```

#### Compiling Figure 2
layout <- '
AAAAAB
AAAAAB
AAAAAB
AAAAA#
AAAAAC
AAAAAC
AAAAAC
'
wrap_plots(A=scatter,
  B=enthusiasm_top, C=enthusiasm_bottom,
  design=layout) + plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))


## Results: Collaboration

### Figure 3: Collaborators per paper
Both panels use data from the same query, saved as `collaborators_per_paper.csv`:

```sql
SELECT aa.article, EXTRACT(month FROM aa.observed) AS month,
	EXTRACT(year FROM aa.observed) AS year,
    COUNT(DISTINCT c.name) AS countries,
    COUNT(DISTINCT aa.id) AS authors
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN institutions i ON ai.institution=i.id
INNER JOIN countries c ON i.country=c.alpha2
GROUP BY 1,2,3
ORDER BY countries DESC, authors DESC
```

#### Figure 3a: Authors per paper
```r
counts <- read.csv('collaborators_per_paper.csv')
counts$time <- ((12*(counts$year - 2013))+counts$month)-10

authormeans = data.frame(
  time=integer(), mean=double(), moving=double()
)
for(year in 2013:2019) {
  for(month in 1:12) {
    timestamp <- ((12*(year - 2013))+month)-10
    authormeans <- rbind(authormeans,
                         c(timestamp,
                           Hmean(counts[counts$time==timestamp,]$authors),
                           Hmean(counts[counts$time<=timestamp,]$authors)
                         )
    )
  }
}
colnames(authormeans) <- c('time','mean', 'moving')

monthly_authors <- ggplot(authormeans, aes(x=time, y=mean)) +
  geom_point() +
  geom_line(aes(x=time, y=moving), color='blue', size=1) +
  scale_x_continuous(
    limits=c(1,74),
    expand=c(0.01, 0.01),
    breaks = NULL
  ) +
  scale_y_continuous(breaks=seq(2.5, 5, 0.5)) +
  labs(x='Month', y='Authors per preprint (harmonic mean)') +
  theme_bw() +
  basetheme +
  theme(
    axis.text.x=element_blank(),
    axis.title.x=element_blank(),
    plot.margin = unit(c(1,1,1,1), "lines"),
  )

monthly_authors <- add_year_x(monthly_authors, TRUE, 2.17)
monthly_authors <- ggplot_gtable(ggplot_build(monthly_authors))
monthly_authors$layout$clip[monthly_authors$layout$name == "panel"] <- "off"
```

Correlation between monthly mean authors per paper and time:
```r
cor.test(authormeans$time, authormeans$mean, method='pearson')
```

#### Figure 3b: Countries per paper
```r
countrymeans = data.frame(
  time=integer(), mean=double(), moving=double()
)
for(year in 2013:2019) {
  for(month in 1:12) {
    timestamp <- ((12*(year - 2013))+month-10)
    countrymeans <- rbind(countrymeans,
                   c(timestamp,
                     mean(counts[counts$time==timestamp,]$countries),
                     mean(counts[counts$time<=timestamp,]$countries)
                   )
    )
  }
}
colnames(countrymeans) <- c('time','mean', 'moving')

monthly_country <- ggplot(countrymeans) +
  geom_point(aes(x=time, y=mean)) +
  geom_line(aes(x=time, y=moving), color='blue', size=1) +
  scale_x_continuous(
    limits=c(1,74),
    expand=c(0.01, 0.01),
    breaks = NULL
  ) +
  #geom_smooth(se=FALSE, method="lm", size=0.75) +
  labs(x='Month', y='Countries per preprint (arithmetic mean)') +
  theme_bw() +
  basetheme +
  theme(
    axis.text.x=element_blank(),
    axis.title.x=element_text(vjust=-4),
    plot.margin = unit(c(1,1,1,1), "lines"),
  )

monthly_country <- add_year_x(monthly_country, TRUE, 1.408)
monthly_country <- ggplot_gtable(ggplot_build(monthly_country))
monthly_country$layout$clip[monthly_country$layout$name == "panel"] <- "off"
```

#### Compiling Figure 3
```r
plot_grid(monthly_authors, monthly_country, nrow=2, ncol=1, align='v')
```



### Table 2: Contributor countries
Table 2 is a subset of data from the following query, which is available in full as **Supplementary Table 3**:

```sql
SELECT totals.country, COALESCE(seniorauthor.preprints,0) AS intl_senior_author,
  COALESCE(anyauthor.preprints,0) AS intl_any_author,
  totals.preprints AS all_any_author
FROM (
	SELECT c.name AS country, COUNT(DISTINCT aa.article) AS preprints
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	GROUP BY 1
) AS totals
LEFT JOIN (
	SELECT c.name AS country, COUNT(DISTINCT aa.article) AS preprints
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	WHERE aa.article IN ( --- only include international papers
		SELECT DISTINCT article
		FROM (
			SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
			FROM article_authors aa
			INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
			INNER JOIN institutions i ON ai.institution=i.id
			INNER JOIN countries c ON i.country=c.alpha2
			WHERE i.id > 0
			GROUP BY aa.article
		) AS countrz
		WHERE countrycount >= 2
	)
	GROUP BY c.name
) AS anyauthor ON totals.country=anyauthor.country
LEFT JOIN (
	SELECT c.name AS country, COUNT(aa.article) AS preprints
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	WHERE aa.id IN ( --- only look at senior-author entries
		SELECT MAX(id)
		FROM article_authors
		GROUP BY article
	) AND aa.article IN (--- only include international papers
		SELECT DISTINCT article
		FROM (
			SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
			FROM article_authors aa
			INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
			INNER JOIN institutions i ON ai.institution=i.id
			INNER JOIN countries c ON i.country=c.alpha2
			WHERE i.id > 0
			GROUP BY aa.article
		) AS countrz
		WHERE countrycount >= 2
	)
	GROUP BY c.name
) AS seniorauthor ON totals.country=seniorauthor.country
ORDER BY intl_senior_author DESC, intl_any_author DESC
```

### Figure 4: International senior authorship

#### Figure 4a: International preprints against international senior author rate
Uses the same data as in **Table 2**. Building the panel:

```r
data <- read.csv('supp_table03.csv')
data <- cleanup_countries(data)
# limit to countries with >= 30 international preprints
data <- data[data$intl_any_author>30,]

a <- ggplot(data=data, aes(x=intl_any_author, y=intl_senior_author_rate)) +
  geom_point(aes(color=as.factor(contributor)), size=2.5) +
  scale_x_log10(labels=comma) +
  scale_color_manual(values=c('#000000','red')) +
  labs(x='International preprints, any author', y='% international senior authorship') +
  geom_smooth(method='lm', formula= y~x, se=FALSE, size=0.5) +
  theme_bw() +
  basetheme +
  theme(
    legend.position = 'none'
  )
```

#### Figure 4b: International senior author rate
*tk

#### Figure 4c: Collaborator countries and senior authorship

Data for this figure is available as **Supplementary Table 4**, generated with this query:

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

Building the panel:

```r
data=read.csv('supp_table04.csv')
data <- data[data$senior != 'UNKNOWN',]
data$senior <- as.character(data$senior) # switch it so we can reset some more easily
data$senior[data$senior=='United States of America'] <-'United\nStates'
data$senior[data$senior=='United Kingdom of Great Britain and Northern Ireland'] <-'United\nKingdom'
data$senior <- as.factor(data$senior)

data$contributor <- as.character(data$contributor)
data$contributor[data$contributor=='Tanzania, United Republic of'] <-'Tanzania'
data$contributor[data$contributor=='Bolivia (Plurinational State of),'] <-'Bolivia'
data$contributor[data$contributor=='Viet Nam'] <-'Vietnam'
data$contributor <- as.factor(data$contributor)

tokeep <- aggregate(data$count, by=list(countries=data$senior), FUN=sum)

# use these colors for the strata, so they match the senior author colors:
colors <- c('white','white','white','white','white','white','white','white','white','white',
            'white','white','white','white','white','white','white','white','white',
            "#999999","#F781BF","#A65628","#FFFF33","#FF7F00","#984EA3","#4DAF4A","#377EB8","#E41A1C")
# only include senior countries with > 25 preprints listed
toplot <- data[data$senior %in% tokeep[tokeep$x > 25,]$countries,]

c <- ggplot(toplot, aes(y = count, axis1=contributor, axis2=senior)) +
  geom_alluvium(aes(fill=senior), width = 1/12) +
  geom_stratum(width = 1/6, color = "gray", fill=colors) +
  geom_label(stat = "stratum", infer.label = TRUE) +
  scale_fill_brewer(palette = 'Set1', aesthetics = c('fill')) +
  #scale_x_continuous(expand=c(0,0)) +
  scale_y_continuous(expand=c(0,0)) +
  theme_void() +
  basetheme +
  theme(
    legend.position='none',
    axis.text.x=element_blank(),
    axis.text.y=element_blank(),
    axis.title.y=element_blank(),
    plot.margin = unit(c(1,0,1,0.25), "lines")
  )
```

#### Compiling Figure 4
```r
compiled <- (a / b)
compiled <- compiled | c
compiled <- compiled + plot_layout(widths=c(1,2))
compiled + plot_annotation(
  tag_levels = 'a',
  tag_prefix = '(',
  tag_suffix = ')',
) & theme(plot.tag=element_text(face='bold'))
```

## Results: Preprint outcomes

### Figure 5: Downloads and publication rates

#### Figure 5a: Downloads per preprint

Data from this query saved as `downloads_per_paper.csv`:

```sql
SELECT aa.article, dloads.downloads, c.name AS country
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN institutions i ON ai.institution=i.id
INNER JOIN countries c ON i.country=c.alpha2
INNER JOIN (
	SELECT article, SUM(pdf) AS downloads
	FROM article_traffic
	GROUP BY 1
) AS dloads ON aa.article=dloads.article
WHERE aa.id IN (
	SELECT MAX(id)
	FROM article_authors
	GROUP BY article
)
ORDER BY dloads.downloads DESC
```

Building the panel:

```r
dloads <- read.csv('downloads_per_paper.csv')
dloads$counting <- 1 # so we can count papers per country
tokeep <- aggregate(dloads$counting, by=list(country=dloads$country), FUN=sum)
colnames(tokeep) <- c('country','preprints')
tokeep <- tokeep[tokeep$preprints >= 100,]
toplot <- dloads[dloads$country %in% tokeep$country,] %>% select(country,downloads)
toplot <- cleanup_countries(toplot)

dloadplot <- ggplot(toplot, aes(x=reorder(country,downloads,FUN=median), y=downloads)) +
  geom_boxplot(outlier.shape = NA, coef=0) +
  coord_flip(ylim=c(0, 700)) +
  scale_y_continuous(expand=c(0,0)) +
  geom_hline(yintercept=median(dloads$downloads), size=1, color='red') +
  labs(y='Downloads per preprint', x='Country') +
  theme_bw() +
  basetheme
```

#### Figure 5b: Publication rate and total preprints
Uses data from \*tc, plus country-level publication data *for preprints last updated prior to 2019*. Data available in **Supplementary Table 5** from this query:

```sql
SELECT totalpre2019.country, totalpre2019.preprints AS total, COALESCE(publishedpre2019.preprints,0) AS published
FROM (
	SELECT c.name AS country, COUNT(aa.article) AS preprints
	FROM prod.article_authors aa
	INNER JOIN prod.affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN prod.institutions i ON ai.institution=i.id
	INNER JOIN prod.countries c ON i.country=c.alpha2
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM prod.article_authors
		GROUP BY article
	) AND
	EXTRACT(year FROM aa.observed) < 2019 
	GROUP BY c.name
) AS totalpre2019
LEFT JOIN (
	SELECT c.name AS country, COUNT(aa.article) AS preprints
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
) AS publishedpre2019 ON totalpre2019.country=publishedpre2019.country
ORDER BY 2 DESC, 1 DESC
```

Building the panel:

```r
dloads <- read.csv('downloads_per_paper.csv')
dloads <- cleanup_countries(dloads)
counts <- read.csv('supp_table01.csv')
counts <- cleanup_countries(counts)
medians <- ddply(dloads, .(country), summarise, med = median(downloads))
data <- medians %>% inner_join(counts, by=c("country"="country")) %>%
  select(country, med, senior_author)
colnames(data) <- c('country','downloads','preprints')
data <- data[data$preprints >= 100,]
dload_totals <- ggplot(data, aes(x=preprints, y=downloads)) +
  geom_point(size=3) +
  geom_smooth(method='lm', se=FALSE, formula='y~x') +
  scale_x_log10(labels=comma) +
  labs(x='Total preprints, senior author', y='Downloads per preprint') +
  theme_bw() +
  basetheme
```

#### Figure 5c: Median downloads against publication rate

Uses the same data as Figures 5a and 5b. Building the panel:

```r
dloads <- read.csv('downloads_per_paper.csv')
dloads$counting <- 1 # so we can count papers per country
tokeep <- aggregate(dloads$counting, by=list(country=dloads$country), FUN=sum)
colnames(tokeep) <- c('country','preprints')
tokeep <- tokeep[tokeep$preprints >= 100,]
toplot <- dloads[dloads$country %in% tokeep$country,] %>% select(country,downloads)
toplot <- cleanup_countries(toplot)
medians <- aggregate(toplot$downloads, by=list(country=toplot$country), FUN=median)
colnames(medians) <- c('country','downloads')

# Then publication data
pubs <- read.csv('supp_table05.csv')
pubs <- cleanup_countries(pubs)
pubs$pubrate <- pubs$published / pubs$total
medians <- medians %>% inner_join(pubs, by=c("country"="country")) %>%
  select(country,downloads,pubrate)

pubdload <- ggplot(medians, aes(x=downloads, y=pubrate)) +
  geom_point(size=3) +
  geom_smooth(method='lm', se=FALSE, formula='y~x') +
  scale_x_continuous(
    limits=c(193,400),
    breaks=seq(200,400,50)
  ) +
  labs(x='Downloads per preprint', y='Publication rate') +
  theme_bw() +
  basetheme
```

Correlation between publication rate and median downloads per preprint:

```r
cor.test(medians$downloads, medians$pubrate, method='spearman')
```

#### Figure 5d: Publication rate
Uses the same data as Figure 5b. Building the panel:

```r
pubs <- read.csv('supp_table05.csv')
pubs <- cleanup_countries(pubs)
pubs$pubrate <- pubs$published / pubs$total

# we want to display the same countries in the downloads and
# publication rate plots, so load that list here:
dloads <- read.csv('downloads_per_paper.csv')
dloads <- cleanup_countries(dloads)
dloads$counting <- 1 # so we can count papers per country
tokeep <- aggregate(dloads$counting, by=list(country=dloads$country), FUN=sum)
colnames(tokeep) <- c('country','preprints')
tokeep <- tokeep[tokeep$preprints >= 100,]

toplot <- pubs[pubs$country %in% tokeep$country,] %>% select(country,pubrate)


pubrateplot <- ggplot(toplot, aes(x=reorder(country,pubrate, reverse=TRUE), y=pubrate)) +
  geom_bar(stat="identity") +
  geom_hline(yintercept=sum(pubdata$published_pre2019)/sum(pubdata$senior_pre2019), color='red', size=1) + # overall
  labs(y='Proportion published', x='Country') +
  coord_flip() +
  scale_y_continuous(expand=c(0,0), limits=c(0,0.8)) +
  theme_bw() +
  basetheme
```

#### Compiling Figure 5

```r
built <- dloadplot | (dload_totals / pubdload) | pubrateplot
built +
  plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))
```
