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

library(ggrepel)
library(plyr) # for summarise
library(dplyr) # for top_n and select()

library(DescTools) # for harmonic mean

setwd('/Users/rabdill/code/biorxiv_countries/code/paper/figures')
themedarktext = "#707070"
big_fontsize = unit(12, "pt")

basetheme <- theme(
  axis.text.x = element_text(size=big_fontsize, color = themedarktext),
  axis.text.y = element_text(size=big_fontsize, color = themedarktext),
  axis.title.x = element_text(size=big_fontsize, color = themedarktext),
  axis.title.y = element_text(size=big_fontsize, color = themedarktext),
  legend.text = element_text(size=big_fontsize, color = themedarktext),
)


yearline = "black"
yearline_size = 0.5
yearline_alpha = 1
yearline_2014 = 8 # position of first year label
# Adds an x axis with delineations and labels for each year
# plot: A ggplot object
# labels: boolean. Whether to include the year numbers.
# yearlabel: A number indicating a y offset, for vertically positioning the year labels
add_year_x <- function(plot, labels, yearlabel)
{
  # plot: a ggplot object
  # labels: BOOLEAN indicating whether to add labels for each year
  # yearlabel: value indicating where on the y-axis the year labels should fall.
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
  matrix$country <- as.character(matrix$country)
  matrix$country[matrix$country=='United States of America'] <- 'United States'
  matrix$country[matrix$country=='United Kingdom of Great Britain and Northern Ireland'] <- 'United Kingdom'
  matrix$country[matrix$country=='Korea, Republic of'] <- 'South Korea'
  matrix$country[matrix$country=='Taiwan, Province of China'] <- 'Taiwan'
  matrix$country[matrix$country=='Iran (Islamic Republic of),'] <- 'Iran'
  matrix$country[matrix$country=='Russian Federation'] <- 'Russia'
  matrix$country[matrix$country=='Bolivia (Plurinational State of),'] <- 'Bolivia'
  matrix$country[matrix$country=='Venezuela (Bolivarian Republic of),'] <- 'Venezuela'
  matrix$country[matrix$country=='Tanzania, United Republic of'] <- 'Tanzania'
  matrix$country[matrix$country=='Viet Nam'] <- 'Vietnam'
  matrix$country[matrix$country=='Czech Republic'] <- 'Czechia'
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

# brew install udunits
# install.packages('udunits2', type = 'source', repo = 'cran.rstudio.com')
# library(devtools)
# devtools::install_github('edzer/units', type = 'source')
# brew install gdal
# install.packages('sf')
# install.packages('rnaturalearth')
# install.packages("rnaturalearthdata")
# install.packages('rgeos')
library(rnaturalearth)
library(sf)
library(scales)
my_world <- ne_countries(scale='medium', returnclass = 'sf') %>%
  rename(alpha2 = 'iso_a2') %>%
  left_join(data, by = 'alpha2')

toplot <- my_world[-12,] # chop off antarctica

legendplot <- ggplot(toplot) +
  geom_sf(aes(fill = senior_author), color='grey', size=0.1) +
  coord_sf(crs = "+proj=eqearth +wktext") + # changes the projection
  scale_fill_gradientn(
    trans="log10",
    colors=rev(heat.colors(7)),
    na.value='white',
    breaks=c(1,100,1000,10000)
  ) +
  labs(fill='Total preprints')

plotted <- ggplot(data=toplot) +
  geom_sf(aes(fill=senior_author), color='grey', size=0.1) +
  coord_sf(crs = "+proj=eqearth +wktext") + # changes the projection
  scale_fill_gradientn(
    trans="log10",
    colors=rev(heat.colors(7)),
    na.value='white',
    breaks=c(1,100,1000,10000)
  ) +
  labs(fill='Total preprints') +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(size = 0.25, linetype = 'solid',
                                        color = "grey"), 
        legend.position = 'none',
        panel.border = element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()
  )

map <- ggdraw() + draw_plot(plotted) +
  draw_plot(get_legend(legendplot), x = -0.35, y = -0.1)
```

#### Figure 1b: Preprints per country, senior author
Uses the same data as Figure 1d. Building the panel:

```r
monthframe=read.csv('../preprints_over_time.csv')
data <- monthframe[monthframe$month=='2019-12',]
data <- cleanup_countries(data)
senior <- ggplot(
  data=data,
  aes(x=reorder(country, running_total), y=running_total, fill=country)
) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0), breaks=seq(0,30000,8000), labels=comma) +
  coord_flip(ylim=c(0,28000)) +
  labs(x = "", y = "Proportion of total preprints, senior author") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set1', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = "none",
    plot.margin = unit(c(2,0.2,1,1), "lines")
  )
```

#### Figure 1c: Preprints per country, any author
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
data <- rbind(data, data.frame(alpha2=NA, country='OTHER',senior_author=10000,any_author=26247)) # dummy value for "senior author"
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
    axis.title.y = element_blank(),
    plot.margin = unit(c(2,1,1,0.2), "lines")
  )
```

#### Figure 1d: Preprints per country over time
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
monthframe=read.csv('../preprints_over_time.csv')
monthframe <- cleanup_countries(monthframe)
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
    plot.margin = unit(c(0,6,1,1), "lines"), # for right-margin labels
  ) +
  annotation_custom(
    grob = textGrob(label = "UNKNOWN", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.04, ymax = 0.04, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "United States", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.3, ymax = 0.3, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "United Kingdom", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.52, ymax = 0.52, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "OTHER", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.72, ymax = 0.72, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "Germany", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.83, ymax = 0.83, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "France", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.88, ymax = 0.88, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "China", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.92, ymax = 0.92, xmin = labelx, xmax = labelx) +
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


#### Compiling Figure 1
```r
map / (senior | any) / time +
plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))

  plot_layout(ncol=3, widths=c(3,4,3)) +
  

plot_grid(
  plot_grid(senior, any, nrow=1,ncol=2, rel_widths=c(4,3),
            labels=c('(b)','(c)'), hjust = c(-0.65, 0.5)
  ),
  time,
  ncol=1, nrow=2, rel_heights=c(2,3), labels=c('','(d)'))
```

Total countries with at least one senior-author preprint:
```sql
SELECT COUNT(DISTINCT i.country)
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN institutions i ON ai.institution=i.id
WHERE aa.id IN (
	SELECT MAX(id)
	FROM article_authors
	GROUP BY article
)
AND i.country != 'UNKNOWN'
```

### Figure 2: Preprint adoption

Data for all panels in this figure are available in **Supplementary Table 2**, which was compiled by adding the senior-author totals from Supplementary Table 1 to data scraped from Scimago. Loading the dataset and calculating the proportions:
```r
data <- read.csv('supp_table02.csv')
data <- cleanup_countries(data)
data$country <- as.character(data$country) 
data[data$country=='United States',]$country <- 'USA'
data[data$country=='United Kingdom',]$country <- 'UK'
data$country <- as.factor(data$country)

data$prop_citable <- data$citable_total / sum(data$citable_total)
data$prop_preprint <- data$senior_author_preprints / 67885
data$adoption <- data$prop_preprint / data$prop_citable
# NOTE: We don't use a live sum of the preprints because this table
# excludes 9000+ "UNKNOWN" preprints
```

#### Figure 2a: Scientific output
```r
# we need an "adoption=1" line to draw through the plot, but
# it's trickier to define with the log scales so this thing just
# defines the endpoints of the line:

oneline <- data.frame(x=c(sum(data$citable_total)/67855, sum(data$citable_total)), y=c(1,67855))

# only reduce the list AFTER calculating adoption so the total citable documents includes everyone
data <- data[data$senior_author_preprints>=50,]

scatter <- ggplot(data) +
  geom_point(aes(x=citable_total, y=senior_author_preprints, color=adoption)) +
  geom_line(data=oneline, aes(x=x, y=y), color='red') +
  geom_text_repel(
    aes(x=citable_total, y=senior_author_preprints, label=country),
    size=4,
    segment.size = 0.5,
    segment.color = "grey50",
    point.padding = 0.15,
    max.iter = 3500
  ) +
  scale_x_log10(labels=comma) +
  scale_y_log10(labels=comma) +
  scale_fill_gradient(limits = c(0,2.2)) +
  coord_cartesian(xlim=c(11400,2900000), ylim=c(48,25500)) +
  labs(x='Citable documents', y='Senior-author preprints', color='bioRxiv adoption') +
  theme_bw() +
  basetheme +
  theme(
    legend.position=c(0.25,0.8)
  )
```

#### Figure 2b: Preprint adoption bar plot
This panel is actually two plots stuck together. The first plot:
```r
adoption_top <- ggplot(data=top_n(data, 10, adoption),
                       aes(x=reorder(country, adoption), y=adoption, fill=adoption)) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0)) +
  scale_fill_gradient(limits = c(0,2.4)) +
  coord_flip(ylim=c(0,2.4)) +
  labs(x = "", y = "") +
  theme_bw() +
  basetheme +
  theme(
    axis.text.x = element_blank(),
    plot.margin = unit(c(0,1,-1,0), "lines"),
    axis.ticks.x = element_blank(),
    panel.grid.minor = element_blank(),
    legend.position = 'none'
  )
```
And the second:
```r
adoption_bottom <- ggplot(data=top_n(data, -10, adoption), aes(x=reorder(country, adoption), y=adoption, fill=adoption)) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0)) +
  scale_fill_gradient(limits = c(0,2.4)) +
  coord_flip(ylim=c(0,2.4)) +
  labs(x = "", y = "bioRxiv adoption") +
  theme_bw() +
  basetheme +
  theme(
    plot.margin = margin(0,1,0,0),
    panel.grid.minor = element_blank(),
    legend.position='none'
  )
```

#### Compiling Figure 2
```r
right <- adoption_top + labs(tag='(b)') + textGrob('(24 other countries...)', gp=gpar(fontface='italic')) + adoption_bottom +
  plot_layout(nrow=3, heights=c(60,1,60))

scatter + labs(tag='(a)') + right + plot_layout(ncol=2, widths=c(5,1)) & theme(plot.tag=element_text(face='bold'))
```

## Results: Collaboration

Count of preprints with at least two countries:

```sql
SELECT COUNT(DISTINCT article) 
FROM (
  SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
  FROM article_authors aa
  INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
  INNER JOIN institutions i ON ai.institution=i.id
  INNER JOIN countries c ON i.country=c.alpha2
  WHERE i.id > 0
  GROUP BY aa.article
) AS counts
WHERE countrycount > 1
```

### Figure 3: Contributor countries
Built using a subset of the data from this query, available in full as **Supplementary Table 9**:

```sql
SELECT counts.*,
  (intl_senior_author::decimal)/GREATEST(intl_any_author, 1) AS intl_senior_rate,
  (intl_any_author::decimal)/all_any_author AS intl_collab_rate,
  (CASE WHEN (intl_any_author >= 50 AND (intl_senior_author::decimal)/GREATEST(intl_any_author, 1) < 0.2) THEN 'TRUE' ELSE 'FALSE' END) AS contributor
FROM (
  SELECT totals.country, totals.alpha2, COALESCE(seniorauthor.preprints,0) AS intl_senior_author,
    COALESCE(anyauthor.preprints,0) AS intl_any_author,
    totals.preprints AS all_any_author
  FROM (
    SELECT c.name AS country, c.alpha2, COUNT(DISTINCT aa.article) AS preprints
    FROM article_authors aa
    INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
    INNER JOIN institutions i ON ai.institution=i.id
    INNER JOIN countries c ON i.country=c.alpha2
    GROUP BY 1,2
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
) AS counts
```

#### Figure 3a: International senior author rate
Panels A through C use this data:
```r
contribs <- read.csv('supp_table09.csv')
contribs <- cleanup_countries(contribs)

# figure out overall rates
# senior author rate
overall.sen_rate <- sum(contribs$intl_senior_author) / sum(contribs$intl_any_author)
# international collab rate
overall.intl_rate <- sum(contribs$intl_any_author) / sum(contribs$all_any_author)
# total preprints
overall.intl_any <- median(contribs$intl_any_author)

contribs <- contribs[(contribs$contributor=='TRUE'),]

# add other countries for comparison
top <- read.csv('supp_table09.csv')
top <- top_n(top[top$intl_any_author > 50,], 5, intl_senior_rate)

contribs <- rbind(contribs, top)
contribs <- cleanup_countries(contribs)
contribs <- arrange(contribs, -intl_senior_rate)
contribs$color <- colors <- c('top1','top2','top1','top2','top1',rep(c('contrib1','contrib2'), 9))
manual_fill <- scale_fill_manual(values=c('#E41A1C', '#db6363', '#d1d1d1', '#999999'))
```
Build panel B:

```r
senior_rate <- ggplot(contribs, aes(x=reorder(country, -intl_senior_rate), y=intl_senior_rate, fill=colors)) +
  geom_bar(stat="identity") +
  geom_hline(yintercept=overall.sen_rate, linetype=2) +
  coord_flip() +
  scale_y_continuous(expand=c(0,0), labels=label_percent(accuracy=1)) +
  labs(x='', y="Internat'l senior author rate") +
  manual_fill +
  theme_bw() +
  basetheme +
  theme(
   legend.position = 'none'
  )
```

#### Figure 3b: International collaboration rate

```r
intl_rate <- ggplot(contribs, aes(x=reorder(country, -intl_senior_rate), y=intl_collab_rate, fill=colors)) +
  geom_bar(stat="identity") +
  geom_hline(yintercept=overall.intl_rate, linetype=2) +
  coord_flip() +
  scale_y_continuous(expand=c(0,0), limits=c(0, 1.05), labels=label_percent(accuracy=1)) +
  labs(x='', y="Internat'l collaboration rate") +
  manual_fill +
  theme_bw() +
  basetheme +
  theme(
    legend.position = 'none',
    axis.text.y = element_blank()
  )
```

#### Figure 3c: International preprints total

```r
total <- ggplot(contribs, aes(x=reorder(country, -intl_senior_rate), y=intl_any_author, fill=colors)) +
  geom_bar(stat="identity") +
  coord_flip() +
  labs(x='', y="Internat'l preprints (any author)") +
  scale_y_continuous(expand=c(0,0), labels=comma) +
  manual_fill +
  theme_bw() +
  basetheme +
  theme(
    legend.position = 'none',
    axis.text.y = element_blank()
  )
```

#### Figure 3d: Collaborator countries and senior authorship

Data for this figure is available as **Supplementary Table 3**, generated with this query:

```sql
SELECT contributor, senior, COUNT(DISTINCT article)
FROM (
	SELECT DISTINCT ON (aa.article, c.name) aa.article, c.name AS contributor, seniors.country AS senior
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	LEFT JOIN (
		SELECT aa.article, c.name AS country
		FROM article_authors aa
		INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
		INNER JOIN institutions i ON ai.institution=i.id
		INNER JOIN countries c ON i.country=c.alpha2
		WHERE aa.id IN ( --- only show entry for senior author on each paper
			SELECT MAX(id)
			FROM article_authors
			GROUP BY article
		) AND ---exclude the senior-author papers from contributor countries
		c.alpha2 NOT IN ('CZ', 'TH', 'EE', 'CO', 'GR', 'TR', 'KE', 'BD', 'IS', 'HR', 'EG', 'UG', 'EC', 'TZ', 'VN', 'PE', 'ID', 'SK')
	) AS seniors ON aa.article=seniors.article
	WHERE aa.article IN ( --- only show international papers
		SELECT DISTINCT article
		FROM (
			SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
			FROM article_authors aa
			INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
			INNER JOIN institutions i ON ai.institution=i.id
			INNER JOIN countries c ON i.country=c.alpha2
			WHERE i.id > 0
			GROUP BY aa.article
			ORDER BY countrycount DESC
		) AS countrz
		WHERE countrycount >= 2
	) AND aa.id IN ( --- list all entries for authors from contributor countries
		SELECT aa.id
		FROM article_authors aa
		INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
		INNER JOIN institutions i ON ai.institution=i.id
		INNER JOIN countries c ON i.country=c.alpha2
		WHERE c.alpha2 IN ('CZ', 'TH', 'EE', 'CO', 'GR', 'TR', 'KE', 'BD', 'IS', 'HR', 'EG', 'UG', 'EC', 'TZ', 'VN', 'PE', 'ID', 'SK')
	)
) AS intntl
WHERE senior IS NOT NULL
GROUP BY 1,2
```

Building the panel:

```r
data=read.csv('supp_table03.csv')
data <- data[data$senior != 'UNKNOWN',]
data$senior <- as.character(data$senior) # switch it so we can reset some more easily
data$senior[data$senior=='United States of America'] <-'United\nStates'
data$senior[data$senior=='United Kingdom of Great Britain and Northern Ireland'] <-'United\nKingdom'
data$senior <- as.factor(data$senior)

data$contributor <- as.character(data$contributor)
data$contributor[data$contributor=='Tanzania, United Republic of'] <-'Tanzania'
data$contributor[data$contributor=='Viet Nam'] <-'Vietnam'
data$contributor <- as.factor(data$contributor)

tokeep <- aggregate(data$count, by=list(countries=data$senior), FUN=sum)
toplot <- data[data$senior %in% tokeep[tokeep$x > 25,]$countries,]
# use these colors for the strata, so they match the senior author colors:
colors <- c("#8fccff","#005fad","#984EA3","#FF7F00","#4DAF4A","#FFFF33","#999999","#A65628","#F781BF")
boxes <- c(rep('white',18), rev(colors))
# only include senior countries with > 25 preprints listed

alluvial <- ggplot(toplot, aes(y = count, axis1=contributor, axis2=senior)) +
  geom_alluvium(aes(fill=senior), width = 1/12, alpha=0.65) +
  geom_stratum(width = 1/6, color = "gray", fill=boxes) +
  geom_label(stat = "stratum", infer.label = TRUE) +
  scale_fill_manual(values=colors) +
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

#### Compiling Figure 3
```r
senior_rate + intl_rate + total + alluvial +
  plot_layout(ncol=4, widths=c(1,1,1,2)) +
  plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))
```

#### Evaluating unusually strong links between collaborators and senior authors
Build a list of unique contries for each preprint, paired with the country of the senior author for that preprint. This is saved as `senior_authors.csv`:

```sql
SELECT aa.article, seniors.country AS senior, c.name AS country, COUNT(aa.id) AS authors
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN institutions i ON ai.institution=i.id
INNER JOIN countries c ON i.country=c.alpha2
INNER JOIN (
  SELECT aa.article, c.name AS country
  FROM article_authors aa
  INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
  INNER JOIN institutions i ON ai.institution=i.id
  INNER JOIN countries c ON i.country=c.alpha2
  WHERE aa.id IN (
    SELECT MAX(id)
    FROM article_authors
    GROUP BY article
  )
) AS seniors ON aa.article=seniors.article
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
AND seniors.country != c.name --- ignore collaborators from the senior author's country
GROUP BY 1,2,3 -- this means we only get one entry per country per article, even if multiple authors on that paper are from the same country
```

We also need to find the list of countries that appear as senior author on international preprints that have an author from at least one contributor country:
```sql
SELECT senior, COUNT(DISTINCT article)
FROM (
	SELECT DISTINCT ON (aa.article, c.name) aa.article, c.name AS contributor, seniors.country AS senior
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	LEFT JOIN (
		SELECT aa.article, c.name AS country
		FROM article_authors aa
		INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
		INNER JOIN institutions i ON ai.institution=i.id
		INNER JOIN countries c ON i.country=c.alpha2
		WHERE aa.id IN ( --- only show entry for senior author on each paper
			SELECT MAX(id)
			FROM article_authors
			GROUP BY article
		) AND ---exclude the senior-author papers from contributor countries
		c.alpha2 NOT IN ('CZ', 'TH', 'EE', 'CO', 'GR', 'TR', 'KE', 'BD', 'IS', 'HR', 'EG', 'UG', 'EC', 'TZ', 'VN', 'PE', 'ID', 'SK')
	) AS seniors ON aa.article=seniors.article
	WHERE aa.article IN ( --- only show international papers
		SELECT DISTINCT article
		FROM (
			SELECT aa.article, COUNT(c.alpha2) AS authorcount, COUNT(DISTINCT c.alpha2) AS countrycount
			FROM article_authors aa
			INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
			INNER JOIN institutions i ON ai.institution=i.id
			INNER JOIN countries c ON i.country=c.alpha2
			WHERE i.id > 0
			GROUP BY aa.article
			ORDER BY countrycount DESC
		) AS countrz
		WHERE countrycount >= 2
	) AND aa.id IN ( --- list all entries for authors from contributor countries
		SELECT aa.id
		FROM article_authors aa
		INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
		INNER JOIN institutions i ON ai.institution=i.id
		INNER JOIN countries c ON i.country=c.alpha2
		WHERE c.alpha2 IN ('CZ', 'TH', 'EE', 'CO', 'GR', 'TR', 'KE', 'BD', 'IS', 'HR', 'EG', 'UG', 'EC', 'TZ', 'VN', 'PE', 'ID', 'SK')
	)
) AS intntl
WHERE senior IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
```

Then perform Fisher's exact tests. The results (in the "combos" variable) are available as **Supplementary Table 4**.
```r
papers <- read.csv('senior_authors.csv')
papers <- cleanup_countries(papers) # note: this ONLY standardizes the contributor countries, not the senior-author ones
contributors <- c('Uganda', 'Vietnam', 'Tanzania', 'Croatia', 'Slovakia', 'Indonesia', 'Thailand', 'Greece', 'Kenya', 'Bangladesh', 'Egypt', 'Ecuador', 'Estonia', 'Peru', 'Turkey', 'Czechia', 'Colombia', 'Iceland')
seniors <- c('United States of America','United Kingdom of Great Britain and Northern Ireland','Switzerland','Sweden','Netherlands','Germany','France','Canada','Australia')

totals <- read.csv('supp_table09.csv') # international preprints per country
overall <- sum(totals$intl_senior_author)

combos <- data.frame(contributor=character(), senior=character(),  p=double(), with=integer(), without=integer(), seniortotal=integer())

for(contributor in contributors) {
  subset <- papers[papers$country==contributor,]
  for(senior in seniors) {
    if(length(subset[subset$senior==senior,]$article) < 10) next # skip links with 5 or fewer papers between a contributor and a senior author country
    contingency <- c(
      length(subset[subset$senior==senior,]$article), # collab and senior
      length(subset[subset$senior!=senior,]$article), # collab, no senior
      totals[totals$country==senior,]$intl_senior_author - length(subset[subset$senior==senior,]$article), # no collab, senior
      overall -  totals[totals$country==senior,]$intl_senior_author - length(subset[subset$senior!=senior,]$article) # no collab, no senior
    )
    contingency <- matrix(contingency, nrow = 2,
     dimnames = list(senior = c("With senior", "Without senior"),
        contributor = c("With contributor", "Without contributor")))
    fishtest <- fisher.test(contingency, alternative = "greater")
    entry <- list(
      contributor=contributor,
      senior=senior,
      p = fishtest$p.value,
      with = length(subset[subset$senior==senior,]$article),
      without = length(subset[subset$senior!=senior,]$article),
      seniortotal = totals[totals$country==senior,]$intl_senior_author
    )
    combos <- rbind(combos, entry, stringsAsFactors=FALSE)
  }
}
combos$padj <- combos$p * length(combos$contributor)
```


## Results: Preprint outcomes

### Figure 4: Downloads and publication rates

#### Figure 4a: Downloads per preprint

Data from this query saved as `downloads_per_paper.csv` and includes ONLY downloads for each preprint's first three months online:

```sql
SELECT aa.article, dloads.downloads, c.name AS country
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN institutions i ON ai.institution=i.id
INNER JOIN countries c ON i.country=c.alpha2
INNER JOIN (
	SELECT article, SUM(pdf) AS downloads
	FROM (
    SELECT article, pdf
    FROM (
      SELECT *,
        rank() OVER (
          PARTITION BY article
          ORDER BY year ASC, month ASC
        )
      FROM article_traffic
    ) AS ordered_data
    WHERE rank <= 6
  ) AS top3
	GROUP BY 1
) AS dloads ON aa.article=dloads.article
WHERE aa.id IN (
	SELECT MAX(id)
	FROM article_authors
	GROUP BY article
) AND aa.article IN (
  SELECT article FROM (
    SELECT article, COUNT(id) AS months
    FROM article_traffic
    GROUP BY article
  ) AS countmonths
  WHERE months>=6
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
  labs(y='Downloads per preprint', x='') +
  theme_bw() +
  basetheme
```

#### Figure 4b: Publication rate and total preprints
Uses data from Figure 4a, plus country-level publication data *for preprints last updated prior to 2019*. Data available in **Supplementary Table 5** from this query:

```sql
SELECT totalpre2019.country, totalpre2019.preprints AS total, COALESCE(publishedpre2019.preprints,0) AS published
FROM (
	SELECT c.name AS country, COUNT(aa.article) AS preprints
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM article_authors
		GROUP BY article
	) AND
	EXTRACT(year FROM aa.observed) < 2019 
	GROUP BY c.name
) AS totalpre2019
LEFT JOIN (
	SELECT c.name AS country, COUNT(aa.article) AS preprints
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	INNER JOIN publications p ON aa.article=p.article
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM article_authors
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

#### Figure 4c: Median downloads against publication rate

Uses the same data as Figures 4a and 4c. Building the panel:

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

# Then pull in publication data
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
  scale_y_continuous(labels=label_percent(accuracy=1)) +
  labs(x='Downloads per preprint', y='Publication rate') +
  theme_bw() +
  basetheme
```

#### Figure 4d: Publication rate
Uses the same data as Figure 6b. Building the panel:

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

pubrateplot <- ggplot(toplot, aes(x=reorder(country,pubrate, reverse=TRUE), y=pubrate, fill=pubrate)) +
  geom_bar(stat="identity") +
  geom_hline(yintercept=sum(pubs$published)/sum(pubs$total), color='red', size=1) + # overall
  labs(y='Publication rate', x='') +
  coord_flip() +
  scale_y_continuous(expand=c(0,0), limits=c(0,0.8), labels=label_percent(accuracy=1)) +
  theme_bw() +
  basetheme +
  theme(
    legend.position='none'
  )
```

#### Compiling Figure 4

```r
built <- dloadplot | (dload_totals / pubdload) | pubrateplot
built +
  plot_layout(ncol=3, widths=c(3,4,3)) +
  plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))
```

#### Correlations
```r
dloads <- read.csv('downloads_per_paper.csv')
dloads$counting <- 1 # so we can count papers per country
tokeep <- aggregate(dloads$counting, by=list(country=dloads$country), FUN=sum)
colnames(tokeep) <- c('country','preprints')
tokeep <- tokeep[tokeep$preprints >= 100,]
toplot <- dloads[dloads$country %in% tokeep$country,] %>% select(country,downloads)
toplot <- cleanup_countries(toplot)
# calculate downloads per paper:
medians <- aggregate(toplot$downloads, by=list(country=toplot$country), FUN=median)
colnames(medians) <- c('country','downloads')
# then get publication rate
pubs <- read.csv('supp_table05.csv')
pubs <- cleanup_countries(pubs)
pubs$pubrate <- pubs$published / pubs$total
medians <- medians %>% inner_join(pubs, by=c("country"="country")) %>%
  select(country,downloads,pubrate)

# also add total preprints:
totals <- read.csv('supp_table01.csv')
totals <- cleanup_countries(totals) %>% select(country, senior_author)
colnames(totals) <- c('country','preprints')
medians <- medians %>% inner_join(totals, by=c("country"="country")) %>%
  select(country,downloads,pubrate, preprints)

cor.test(medians$downloads, medians$preprints, method='spearman')
cor.test(medians$downloads, medians$pubrate, method='spearman')
```

### Table 2: Journal/country links
Saved as `preprints_per_journal.csv`:

```sql
SELECT c.name AS country, p.journal, COUNT(aa.article) AS preprints
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN institutions i ON ai.institution=i.id
INNER JOIN countries c ON i.country=c.alpha2
INNER JOIN publications p ON aa.article=p.article
WHERE aa.id IN (
	SELECT MAX(id)
	FROM article_authors
	GROUP BY article
)
AND aa.observed < '2019-01-01'
GROUP BY 1,2
ORDER BY 1,3 DESC
```

Processing into the table, saved in full as **Supplementary Table 6**:
```r
chitest <- function(row) {
  result <- prop.test(x=row$preprints, n=row$journaltotal, p=row$countrytotal/23102, alternative = "greater")
  return(result$p.value)
}
jlinks <- read.csv('country_journals.csv')
jlinks <- cleanup_countries(jlinks)
colnames(jlinks) <- c('country','journal','preprints')
# figure out total preprints per journal
journal_totals <- ddply(jlinks, .(journal), summarise, journaltotal = sum(preprints))
# and per country:
country_totals <- ddply(jlinks, .(country), summarise, journaltotal = sum(preprints))
# incorporate totals:
jlinks <- jlinks %>% inner_join(journal_totals, by=c('journal'='journal'))
jlinks <- jlinks %>% inner_join(country_totals, by=c('country'='country'))
colnames(jlinks) <- c('country','journal','preprints','journaltotal','countrytotal')
totalpubs <- sum(jlinks$preprints)
jlinks <- jlinks[jlinks$country != 'UNKNOWN',]
# do the testing:
jlinks$p <- by(jlinks, 1:nrow(jlinks), chitest)
jlinks$expected <- (jlinks$countrytotal / totalpubs) * jlinks$journaltotal
jlinks <- jlinks[jlinks$preprints >= 15,]

jlinks$padj <- p.adjust(jlinks$p, method='BH')
table <- table[table$padj <= 0.05,] %>% select(country, journal, preprints, expected, p, padj, journaltotal, countrytotal)
```

## Methods

### Countries of first and last author

Count of how many preprints have country data for the first and last author, AND that they are different countries:

```sql
SELECT COUNT(DISTINCT first.article)
FROM (
	SELECT aa.article, c.name
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	WHERE aa.id IN (
		SELECT MIN(id)
		FROM article_authors
		GROUP BY article
	)
) AS first
INNER JOIN (
	SELECT aa.article, c.name
	FROM article_authors aa
	INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
	INNER JOIN institutions i ON ai.institution=i.id
	INNER JOIN countries c ON i.country=c.alpha2
	WHERE aa.id IN (
		SELECT MAX(id)
		FROM article_authors
		GROUP BY article
	)
) AS last ON first.article=last.article
WHERE first.name != last.name
AND first.name != 'UNKNOWN'
AND last.name != 'UNKNOWN'
```

### Alternative counting methods

Complete-normalized counting, saved as **Supplemental Table 7**:

```sql
SELECT completenormalized.country, completenormalized.share AS cn_total,
  total.preprints AS straight_count
FROM (
  SELECT c.name AS country, SUM(1/cpa.authors::decimal) AS share
  FROM article_authors aa
  INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
  INNER JOIN institutions i ON ai.institution=i.id
  INNER JOIN countries c ON i.country=c.alpha2
  INNER JOIN ( --- authors per article
    SELECT article, COUNT(DISTINCT id) AS authors
    FROM article_authors
    GROUP BY article
  ) AS cpa ON cpa.article=aa.article
  GROUP BY c.name
) AS completenormalized
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
) AS total ON completenormalized.country=total.country
ORDER BY 3,2
```

Correlation test between counting methods:

```r
counts <- read.csv('supp_table07.csv')
x <- cor.test(counts$cn_total, counts$whole_count)
x$p.value
```

### Figure 5: Journal links
Data saved as `country_journals.csv`:

```sql
SELECT c.name AS country, p.journal, COUNT(aa.article) AS preprints
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
INNER JOIN institutions i ON ai.institution=i.id
INNER JOIN countries c ON i.country=c.alpha2
INNER JOIN publications p ON aa.article=p.article
WHERE aa.id IN (
	SELECT MAX(id)
	FROM article_authors
	GROUP BY article
)
GROUP BY 1,2
ORDER BY 1,3 DESC
```

Setting up the data:

```r
chitest <- function(row) {
  result <- prop.test(x=row$preprints, n=row$journaltotal, p=row$countrytotal/23102, alternative = "greater")
  return(result$p.value)
}

jlinks <- read.csv('country_journals.csv')
jlinks <- cleanup_countries(jlinks)
colnames(jlinks) <- c('country','journal','preprints')
# figure out total preprints per journal
journal_totals <- ddply(jlinks, .(journal), summarise, journaltotal = sum(preprints))
# and per country:
country_totals <- ddply(jlinks, .(country), summarise, journaltotal = sum(preprints))
# incorporate totals:
jlinks <- jlinks %>% inner_join(journal_totals, by=c('journal'='journal'))
jlinks <- jlinks %>% inner_join(country_totals, by=c('country'='country'))
colnames(jlinks) <- c('country','journal','preprints','journaltotal','countrytotal')
totalpubs <- sum(jlinks$preprints)
jlinks <- jlinks[jlinks$country != 'UNKNOWN',]
jlinks <- jlinks[jlinks$preprints >= 15,] # leave out links without very many preprints
# do the testing:
jlinks$p <- by(jlinks, 1:nrow(jlinks), chitest)
jlinks$expected <- (jlinks$countrytotal / totalpubs) * jlinks$journaltotal

jlinks$padj <- p.adjust(jlinks$p, method='BH')
```

#### Figure 5a: Country/journal links
```r
#sizing is p value
new <- jlinks %>% select(country, journal, preprints, padj)
tokeep.journal <- new[new$padj <= 0.05,]$journal
tokeep.country <- new[new$padj <= 0.05,]$country
new <- new[new$country %in% tokeep.country,]
new <- new[new$journal %in% tokeep.journal,]

new$size <- 1-new$padj
quant <- ecdf(new$size)
new$size <- quant(new$size)

toplot <- new[new$padj <= 0.05,]

# rearrange the axes
toplot$counting <- 1 # for counting significant links
journal_totals <- ddply(toplot, .(journal), summarise, journaltotal = sum(counting))
country_totals <- ddply(toplot, .(country), summarise, countrytotal = sum(counting))
toplot <- toplot %>% inner_join(journal_totals, by=c('journal'='journal'))
toplot <- toplot %>% inner_join(country_totals, by=c('country'='country'))
xorder <- toplot %>% arrange(-countrytotal)
xorder <- unique(xorder$country)
yorder <- toplot %>% arrange(journaltotal)
yorder <- unique(yorder$journal)

background <- expand.grid(unique(toplot$journal), unique(toplot$country))
colnames(background) <- c('journal','country')
heat <- ggplot() + 
  # first the grid:
  geom_tile(data=background, aes(x=country, y=journal, height=1, width=1), color='grey', fill='white') +
  # then the real data:
  geom_tile(data=toplot, # the real boxes
    aes(
      x=country,
      y=journal,
      #x=reorder(country, -countrytotal),
      #y=reorder(journal, journaltotal),
      fill=preprints, height=size, width=size
    )
  ) + 
  scale_x_discrete(position = "top", limits=xorder) +
  scale_y_discrete(limits=yorder) +
  scale_fill_distiller(name='Preprints', palette = "Reds", direction=1, trans = "log", labels=label_number(accuracy=1)) +
  coord_fixed() + # to keep the tiles square
  labs(x='Country', y='Journal') +
  theme_bw() +
  basetheme +
  theme(
    axis.text.x=element_text(angle=65, vjust=0, hjust=0),
    panel.background=element_blank(),
    panel.grid.minor=element_blank(),
    panel.grid.major=element_blank(),
    axis.ticks = element_blank(),
    legend.position = c(-1.4,1)
    #legend.direction = 'horizontal',
    #legend.key.width=unit(3,"lines")
  )
```

Building the legend for tile size:
```r
scaledata <- data.frame(
  country=c(''),
  journal=c('0.05','0.01','0.001'),
  size=c(quant(1-0.05), quant(1-0.01), quant(1-0.001))
)
heatscale <- ggplot() + 
  # first the grid:
  geom_tile(data=scaledata, aes(x=country, y=journal, height=1, width=1), color='black', fill='white') +
  # then the real data:
  geom_tile(data=scaledata, # the real boxes
            aes(
              x=country,
              y=journal,
              fill=max(toplot$preprints), height=size, width=size
            )
  ) + 
  scale_fill_distiller(name='Preprints', palette = "Reds", direction=1, trans = "log", labels=label_number(accuracy=1)) +
  coord_fixed() + # to keep the tiles square
  scale_x_discrete(position = "top") +
  scale_y_discrete(position = "right") +
  labs(x='q-value', y='') +
  theme_void() +
  basetheme +
  theme(
    axis.title.x=element_text(vjust=0, hjust=0, color='black'),
    axis.text.x=element_text(hjust=1),
    panel.background=element_blank(),
    panel.grid.minor=element_blank(),
    panel.grid.major=element_blank(),
    axis.ticks = element_blank(),
    legend.position = 'none'
  )
```

#### Figure 5b: U.S. overrepresentation
```r
newplot <- jlinks[jlinks$country=='United States',]
newplot$over <- (newplot$preprints - newplot$expected)/newplot$expected
newplot <- newplot[newplot$expected >= 30,]
bar <- ggplot(newplot, aes(x=reorder(journal,over), y=over, fill=(newplot$padj <= 0.05))) +
  geom_bar(stat='identity') +
  geom_text(aes(x=reorder(journal,over), y=ifelse(newplot$over > 0, -0.01, 0.01), label=journal),
            hjust=ifelse(newplot$over > 0, 1, 0)) +
  geom_hline(yintercept=0, color='black',size=1) +
  coord_flip() +
  scale_y_continuous(limits=c(-0.5, 0.77),
      breaks=seq(-0.5, 0.75, 0.25), expand=c(0,0), label=percent) +
  labs(y='Overrepresentation of United States',x='Journal') +
  theme_bw() +
  basetheme +
  scale_fill_manual(values=c('#999999','red')) +
  theme(
    legend.position='none',
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
  )
```

#### Compiling Figure 5
```r
plot_grid(heat, bar,
          ncol=2, align='h', axis='b',
          labels=c('(a)','(b)'),
          hjust=c(-1, 0.2)
) + draw_plot(heatscale, x=0.04, y=0.8212, width=0.1, height=0.1)
```

## Supplementary

### Figure 1, figure supplement 1: Collaborators per paper
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

#### Figure 1, figure supplement 1a: Authors per paper
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
x <- cor.test(authormeans$time, authormeans$mean, method='pearson')
x$p.value
```

#### Figure 1, figure supplement 1b: Countries per paper
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

#### Compiling Figure 1, figure supplement 1
```r
plot_grid(monthly_authors, monthly_country,
  nrow=2, ncol=1, align='v', labels=c('(a)','(b)'))
```

Mean countries per paper across all data:
```r
tail(countrymeans,1)$moving
```

#### International preprints per year
```sql
SELECT total.year, total.preprints AS total, intl.preprints AS intl
FROM (
	SELECT EXTRACT(YEAR FROM aa.observed) AS year, COUNT(DISTINCT aa.article) AS preprints
	FROM article_authors aa
	GROUP BY 1
) AS total
LEFT JOIN (
	SELECT EXTRACT(YEAR FROM aa.observed) AS year, COUNT(DISTINCT aa.article) AS preprints
	FROM article_authors aa
	WHERE aa.article IN (--- only include international papers
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
	GROUP BY 1
) AS intl ON total.year=intl.year
ORDER BY 1 ASC
```

#### Figure 3, figure supplement 1: Map of contributor countries

```r
data <- read.csv('supp_table09.csv')
data <- cleanup_countries(data)
data <- data[data$contributor=='TRUE',]

my_world <- ne_countries(scale='medium', returnclass = 'sf') %>%
  rename(alpha2 = 'iso_a2') %>%
  left_join(data, by = 'alpha2')

to_plot <- my_world[-12,] # chop off antarctica

ggplot(data = to_plot) +
  geom_sf(aes(fill = contributor), color='black', size=0.1) +
  coord_sf(crs = "+proj=eqearth +wktext") + # changes the projection
  scale_fill_manual(
    values=c('red'),
    na.translate=TRUE,
    na.value='#ffffff'
  ) +
  theme(panel.background = element_rect(fill = "white"),
        panel.grid.major = element_line(size = 0.25, linetype = 'solid',
                                        color = "grey"), 
        legend.position = 'none',
        panel.border = element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank()
  )
```

### Figure 3, figure supplement 2: Contributor country correlations
```r
data <- read.csv('supp_table09.csv')
data <- cleanup_countries(data)
data <- data[data$intl_any_author>30,]

cor.test(data$intl_senior_rate, data$intl_any_author, method="spearman")
cor.test(data$intl_any_author, data$intl_collab_rate, method="spearman")
cor.test(data$intl_collab_rate, data$intl_senior_rate, method="spearman")
```
#### Figure 3, figure supplement 2a: International authorship compared to total international papers
```r
a <- ggplot(data=data, aes(x=intl_any_author, y=intl_senior_rate)) +
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

#### Figure 3, figure supplement 2b: International authorship compared to international collaboration rate
```r
b <- ggplot(data=data, aes(x=intl_any_author, y=intl_collab_rate)) +
  geom_point(aes(color=as.factor(contributor)), size=2.5) +
  scale_x_log10(labels=comma) +
  scale_color_manual(values=c('#000000','red')) +
  labs(x='International preprints, any author', y='% preprints w/ international collaborators') +
  geom_smooth(method='lm', formula= y~x, se=FALSE, size=0.5) +
  theme_bw() +
  basetheme +
  theme(
    legend.position = 'none'
  )
```

#### Figure 3, figure supplement 2c: International collaboration rate compared to international senior author rate
```r
c <- ggplot(data=data, aes(x=intl_collab_rate, y=intl_senior_rate)) +
  geom_point(aes(color=as.factor(contributor)), size=2.5) +
  scale_color_manual(values=c('#000000','red')) +
  labs(x='% preprints w/ international collaborators', y='% international senior authorship') +
  geom_smooth(method='lm', formula= y~x, se=FALSE, size=0.5) +
  theme_bw() +
  basetheme +
  theme(
    legend.position = 'none'
  )
```

#### Compile Figure 3, figure supplement 2
```r
fig <- a | b | c
fig + plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))
```

## Statements in paper
Number of authors with "unknown" country:
```sql
SELECT COUNT(id)
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
WHERE ai.institution=0
```

Number of affiliation strings with "unknown" country:
```sql
SELECT COUNT(DISTINCT aa.affiliation)
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
WHERE ai.institution=0
```

Select random sample from papers in "unknown" category:
```sql
SELECT aa.name, aa.affiliation, aa.email, aa.article, random() AS randx
FROM article_authors aa
INNER JOIN affiliation_institutions ai ON aa.affiliation=ai.affiliation
WHERE aa.id IN (
  SELECT MAX(id)
  FROM article_authors
  GROUP BY article
) AND 
ai.institution=0
ORDER BY random()
LIMIT 1486
```
