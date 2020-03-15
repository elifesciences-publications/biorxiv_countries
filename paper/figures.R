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


setwd('/Users/rabdill/code/biorxiv_authors/code/paper/data')
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
  matrix$country <- as.factor(matrix$country)
  return(matrix)
}


#---------------------------------
# FIGURE 1: preprints per country

# PANEL: map
data <- read.csv('preprints_country_all.csv', header = TRUE, stringsAsFactors = FALSE)
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

# PANEL: Papers per country over time
monthframe=read.csv('preprints_country_time.csv')
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
    ymin = 0.55, ymax = 0.55, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "OTHER", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.75, ymax = 0.75, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "Germany", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.84, ymax = 0.84, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "France", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.88, ymax = 0.88, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "China", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.92, ymax = 0.92, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "Canada", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 0.96, ymax = 0.96, xmin = labelx, xmax = labelx) +
  annotation_custom(
    grob = textGrob(label = "Australia", hjust = 0, gp = gpar(fontsize = labelsize, col=themedarktext)),
    ymin = 1.0, ymax = 1.0, xmin = labelx, xmax = labelx)

time <- add_year_x(time, TRUE, -0.03)
time <- ggplot_gtable(ggplot_build(time))
time$layout$clip[time$layout$name == "panel"] <- "off"

# PANEL: bar plot, preprints per country
data <- monthframe[monthframe$month=='2019-12',]
overview <- read.csv('overview_by_country.csv') %>%
  select(country,senior_author_rate_international)
overview <- cleanup_countries(overview)
data <- data %>%
  left_join(overview, by=c("country"="country"))

senior <- ggplot(
    data=data,
    aes(x=reorder(country, running_total), y=running_total, fill=country)
  ) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0), breaks=seq(0,30000,8000)) +
  coord_flip(ylim=c(0,28000)) +
  labs(x = "Country", y = "Preprints, senior author") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set1', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = "none"
  )

data[data$country=='OTHER',]$senior_author_rate_international <- 6994/16941
seniorrate <- ggplot(
    data=data,
    aes(x=reorder(country, running_total), y=senior_author_rate_international, fill=country)
  ) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0)) +
  coord_flip(ylim=c(0,0.52)) +
  labs(x = "Country", y = "Senior author rate, international preprints") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set1', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.title.y = element_blank()
  )

# Assemble figure 1 with patchwork

plot_grid(time,
  plot_grid(senior, seniorrate, nrow=1,ncol=2, rel_widths=c(3,2)),
ncol=1, nrow=2)


# FIGURE:
# panel - preprint enthusiasm
data <- read.csv('adjusted_preprints.csv')
toplot <- rbind(data[1:10,], data[52:61,])
enthusiasm <- ggplot(data=toplot, aes(x=reorder(country, proportion_ratio), y=proportion_ratio,
  fill=continent)) +
  geom_bar(stat="identity") +
  geom_vline(xintercept=10.5, color='red') +
  scale_y_continuous(expand=c(0,0)) +
  coord_flip(ylim=c(0,2.8)) +
  labs(x = "Country", y = "bioRxiv enthusiasm") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set2', guide='legend',
    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = "bottom",
    plot.margin = margin(0,0,0,0)
  )

legend <- get_legend(enthusiasm)

enthusiasm <- enthusiasm + theme(legend.position="none")
# panel - total preprints
preprints <- ggplot(data=toplot,
  aes(x=reorder(country, proportion_ratio), y=citable_docs, fill=continent, label=preprints)
) +
  geom_bar(stat="identity") +
  geom_text(aes(label=comma(citable_docs, accuracy=1), y=480000), hjust=0) +
  geom_vline(xintercept=10.5, color='red') +
  scale_y_continuous(expand=c(0,0), labels=comma) +
  coord_flip() +
  labs(x = "Country", y = "Worldwide citable documents") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set2', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.title.y = element_blank()
    #plot.margin = margin(0,0,0,0)
  )

# assemble figure
top <- (enthusiasm + preprints) + plot_layout(widths=c(3,6))

top / legend +
  plot_layout(heights = c(13, 1))

# FIGURE: Institutions

# Panel: preprints per institution
data=read.csv('preprints_per_institution.csv')

data$senior <- data$senior_author
data$nonsenior <- data$any_author - data$senior_author
data$id <- NULL
data$senior_author <- NULL
data <- top_n(data, 16, any_author)
data_long <- gather(data[2:16,], author, qty, senior:nonsenior)

papers_per_institution <- ggplot(data_long, aes(x=reorder(name,any_author),y=qty,fill=author)) +
  geom_bar(position='stack',stat='identity') +
  coord_flip() +
  labs(x='Institution',y='Preprints') +
  theme_bw() +
  scale_fill_brewer(palette = 'Set1', guide='legend',
    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    #legend.position = 'bottom'
    legend.position = c(0.75,0.6)
  )



# NSF FIGURE, DELETE LATER
e <- read.csv('adjusted_preprints.csv')
toplot <- rbind(e[1:8,], e[54:61,])
enthusiasm <- ggplot(data=toplot, aes(x=reorder(country, proportion_ratio), y=proportion_ratio, fill=continent)) +
  geom_bar(stat="identity") +
  geom_vline(xintercept=8.5, color='red') +
  scale_y_continuous(expand=c(0,0)) +
  coord_flip(ylim=c(0,2.8)) +
  labs(x = "Country", y = "bioRxiv enthusiasm") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set2', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = c(0.75,0.3),
    plot.margin = margin(0,0,0,0)
  )

(papers_per_institution / enthusiasm) + plot_annotation(tag_levels = 'a')
# END NSF FIGURE

# FIGURE: Authors

# panel: Authors per paper
authorcounts <- read.csv('authors_per_paper.csv')
colnames(authorcounts) <- c('id','year','authors')

harms <- vector("list", 7)
means <- vector("list", 7)
meds <- vector("list", 7)
sds <- vector("list", 7)
i <- 1
for(year in seq(2013,2019,1)) {
  calc <- Hmean(authorcounts[authorcounts$year==year,]$authors, conf.level=0.95)
  harms[[i]] <- calc[['mean']]
  means[[i]] <- mean(authorcounts[authorcounts$year==year,]$authors)
  sds[[i]] <- sd(authorcounts[authorcounts$year==year,]$authors)
  meds[[i]] <- median(authorcounts[authorcounts$year==year,]$authors)
  i <- i + 1
}
averages <- data.frame(
  year = seq(2013,2019,1),
  harm = unlist(harms, use.names=FALSE),
  #lower = unlist(lower, use.names=FALSE),
  #upper = unlist(upper),
  mean = unlist(means),
  median = unlist(meds)
)

averages_long <- pivot_longer(averages, -year, names_to="average",values_to="value")

per_paper <- ggplot(data=averages_long, aes(x=year, y=value, color=average)) +
  #geom_violin(data=authorcounts, aes(x=year,y=authors,group=year)) + scale_y_continuous(breaks=c(0,1,2,5,10,15,20), limits=c(0,15)) +
  geom_line(size=2) +
  #geom_errorbar(data=sd, aes(x=year, ymin=mean-sd, ymax=mean+sd)) +
  scale_x_continuous(breaks=seq(2013, 2019, 1)) +
  labs(x='Year', y='Authors per preprint') +
  scale_color_discrete(labels=c('harmonic mean','arithmetic mean','median')) +
  theme_bw() +
  basetheme +
  theme(
    legend.title=element_blank(),
    legend.direction='horizontal',
    legend.position=c(0.55,0.06)
  )

# PANEL: countries per paper over time
countries=read.csv('countries_per_paper.csv')
means <- vector("list", 7)
sds <- vector("list", 7)
i <- 1
for(year in seq(2013,2019,1)) {
  means[[i]] <- mean(countries[countries$year==year,]$countries)
  sds[[i]] <- sd(countries[countries$year==year,]$countries)
  i <- i + 1
}
averages <- data.frame(
  year = seq(2013,2019,1),
  mean = unlist(means),
  sd = unlist(sds)
)

countries_time <- ggplot() +
  geom_errorbar(data=averages, aes(x=year, ymin=mean-(sd/2), ymax=mean+(sd/2))) +
  geom_line(data=averages, aes(x=year, y=mean), color='red', size=2) +
  scale_x_continuous(breaks=seq(2013, 2019, 2)) +
  labs(x='Year', y='Countries per preprint') +
  theme_bw() +
  basetheme

# PANEL: countries per paper histogram
countrycount <- ggplot(countries, aes(x=countries)) +
  geom_histogram(bins=30) +
  scale_y_log10(
    labels = scales::number_format(accuracy = 1, big.mark=',')
  ) +
  labs(x="Countries in author list", y="Preprints") +
  theme_bw() +
  basetheme

# compile figure
bottom <- (countries_time + countrycount) #+ plot_layout(widths=c(3,2))
compiled <- per_paper / bottom
compiled + plot_annotation(tag_levels = 'a')


# FIGURE: senior authors by country
data=read.csv('overview_by_country.csv')

# PANEL: Total intl preprints against proportion of international preprints w senior authorship
a <- ggplot(data=data, aes(x=international_papers_any_author, y=seniorinter)) +
  geom_point() +
  scale_x_log10() +
  theme_bw() +
  basetheme +
  labs(x='International preprints, any author', y='% international senior authorship') +
  geom_smooth(method='lm', formula= y~x, se=FALSE)


# PANEL: International senior authorship compared to total international papers

# what proportion of a country's international preprints include a senior author from that country?
data$seniorinter <- data$international_papers_senior_author / data$international_papers_any_author
# what proportion of a country's preprints are international?
data$prop_international <- data$international_papers_any_author / data$preprints_any_author
# limit to countries with >= 30 international preprints
data <- data[data$international_papers_any_author >= 30,]
data <- data[!is.na(data$seniorinter),]

b <- ggplot(data=data, aes(x=prop_international, y=seniorinter)) +
  geom_point() +
  geom_smooth(method='lm', formula= y~x, se=FALSE) +
  theme_bw() +
  basetheme +
  labs(x='% of papers international', y='% international senior authorship')

# PANEL: contributor countries, by senior author
data=read.csv('contributor_country_senior_counts.csv')
data <- data[data$senior != 'UNKNOWN',]
data$senior <- as.character(data$senior) # switch it so we can reset some more easily
data$senior[data$senior=='United States of America'] <-'United States'
data$senior[data$senior=='United Kingdom of Great Britain and Northern Ireland'] <-'United Kingdom'
data$senior <- as.factor(data$senior)

data$contributor <- as.character(data$contributor)
data$contributor[data$contributor=='Tanzania, United Republic of'] <-'Tanzania'
data$contributor[data$contributor=='Bolivia (Plurinational State of),'] <-'Bolivia'
data$contributor[data$contributor=='Viet Nam'] <-'Vietnam'
data$contributor <- as.factor(data$contributor)

tokeep <- aggregate(data$count, by=list(countries=data$senior), FUN=sum)

# only include senior countries with > 25 preprints listed
toplot <- data[data$senior %in% tokeep[tokeep$x > 25,]$countries,]
c <- ggplot(toplot, aes(y = count, axis1=contributor, axis2=senior)) +
  geom_alluvium(aes(fill=senior), width = 1/12) +
  geom_stratum(width = 1/6, color = "grey") +
  geom_label(stat = "stratum", infer.label = TRUE) +
  #ggrepel::geom_text_repel(label='stratum', stat = "stratum", size = 4, direction = "x", nudge_x = -.5) +
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
  )

compiled <- (b / a)
compiled <- compiled | c
compiled <- compiled + plot_layout(widths=c(1,2))
compiled + plot_annotation(tag_levels = 'a')


# FIGURE: OUTCOMES
# panel: downloads per paper
dloads <- read.csv('downloads_per_paper.csv')
dloads <- dloads %>% select(year,country,downloads)
dloads$counting <- 1 # so we can count papers per country
tokeep <- aggregate(dloads$counting, by=list(country=dloads$country), FUN=sum)
colnames(tokeep) <- c('country','preprints')
tokeep <- tokeep[tokeep$preprints >= 100,]
toplot <- dloads[dloads$country %in% tokeep$country,] %>% select(country,downloads)
toplot <- cleanup_countries(toplot)

dloadplot <- ggplot(toplot, aes(x=reorder(country,downloads,FUN=median), y=downloads)) +
  geom_boxplot(outlier.shape = NA, coef=0) +
  coord_flip(ylim=c(0, 700)) +
  geom_hline(yintercept=median(dloads$downloads), size=1, color='red') +
  labs(y='Downloads per preprint', x='Country') +
  theme_bw() +
  basetheme

# calculating median downloads per country
medians <- aggregate(toplot$downloads, by=list(country=toplot$country), FUN=median)
colnames(medians) <- c('country','downloads')
pubs <- read.csv('overview_by_country.csv')
pubs <- cleanup_countries(pubs)
pubs$pubrate <- pubs$published_pre2019 / pubs$senior_pre2019
medians <- medians %>% inner_join(pubs, by=c("country"="country")) %>%
  select(country,downloads,pubrate)
cor.test(medians$downloads, medians$pubrate, method='spearman')

pubdload <- ggplot(medians, aes(x=downloads, y=pubrate)) +
  geom_point(size=3) +
  geom_smooth(method='lm', se=FALSE) +
  labs(x='Downloads per preprint', y='Publication rate') +
  theme_bw() +
  basetheme

# PANEL: downloads by enthusiasm
dloads <- read.csv('downloads_per_paper.csv')
enthusiasm <- read.csv('adjusted_preprints.csv')
medians <- ddply(dloads, .(country), summarise, med = median(downloads))
data <- medians %>% inner_join(enthusiasm, by=c("country"="country")) %>%
  select(country, med, proportion_ratio)
colnames(data) <- c('country','downloads','enthusiasm')
cor.test(data$downloads, data$enthusiasm)

dload_enthusiasm <- ggplot(data, aes(x=enthusiasm, y=downloads)) +
  geom_point(size=4) +
  geom_smooth(method='lm', se=FALSE) +
  labs(x='bioRxiv enthusiasm', y='Downloads per preprint') +
  theme_bw() +
  basetheme

# panel: publication rate
data <- read.csv('overview_by_country.csv')
data$pubrate <- data$published_pre2019 / data$senior_pre2019
tokeep <- data[data$senior_pre2019 >= 50,] %>% select(country,pubrate)
tokeep <- cleanup_countries(tokeep)
toplot <- rbind(head(tokeep,10), tail(tokeep,10))
pubrateplot <- ggplot(toplot, aes(x=reorder(country,pubrate, reverse=TRUE), y=pubrate)) +
  geom_bar(stat="identity") +
  geom_hline(yintercept=sum(data$published_pre2019)/sum(data$senior_pre2019), color='red', size=1) + # overall
  labs(y='Proportion of preprints published', x='Country') +
  coord_flip() +
  theme_bw() +
  basetheme

# using cowplot for this one because panels b and c are different widths
dloadplot | (dload_enthusiasm / pubdload) | pubrateplot
plot_grid(dloadplot,
  plot_grid(dload_enthusiasm, pubrateplot,nrow=2,ncol=1,axis='r', labels=c('(b)','(c)')),
  pubdload,
  ncol=3,nrow=1,axis='tb',
  labels=c('(a)','','(d)'))

# domestic vs international preprint publication rate
data <- read.csv('international_publications_per_country.csv')
tokeep <- data[data$international_total >= 50,]
tokeep <- cleanup_countries(tokeep)
ggplot(tokeep, aes(x=domestic_proportion, y=international_proportion)) +
  geom_point() +
  geom_abline(intercept=0, slope=1, color='red') +
  labs(x='Domestic publication rate', y='International publication rate') +
  theme_bw() +
  basetheme

# COUNTRY SIMILARITY BY JOURNAL PUBLICATIONS
library(ggfortify)
library(vegan)

data <- read.csv('publication_journal_country.csv')
# minimum published preprints, country
country_tokeep <- aggregate(data$preprints, by=list(country=data$country), FUN=sum)
country_tokeep <- country_tokeep[country_tokeep$x >= 80,]
toplot <- data[data$country %in% country_tokeep$country,]
# minimum published preprints, journal
journal_tokeep <- aggregate(toplot$preprints, by=list(journal=toplot$journal), FUN=sum)
journal_tokeep <- journal_tokeep[journal_tokeep$x >= 15,]


toplot <- toplot[toplot$journal %in% journal_tokeep$journal,]
toplot <- cleanup_countries(toplot)
#ggplot(toplot, aes(country, journal, fill=preprints)) + 
#  geom_tile(scale="row")

wide <- pivot_wider(toplot, names_from=c('journal'),
    values_from=c('preprints'))
countries <- wide$country
wide$country <- NULL
wide[is.na(wide)] <- 0
wide <- as.matrix(wide)
rownames(wide) <- countries
prop <- prop.table(wide,margin=1)


#autoplot(prop) # heatmap with journals

#distance <- as.matrix(dist(prop, method='euclidean'))
#colnames(distance) <- countries
#rownames(distance) <- countries
#autoplot(cmdscale(distance, eig = TRUE), label = TRUE) # PCOA
#plot(hclust(as.dist(prop), method='complete')) # dendrogram

# using bray-curtis:
x <- vegdist(prop, method="bray")
autoplot(cmdscale(x, eig = TRUE), label = TRUE)
plot(hclust(as.dist(x)))
autoplot(x) # heatmap



# Journal/institution relationships
data <- read.csv('publication_journal_institution.csv')
data <- data[data$institution!='UNKNOWN',]
# minimum published preprints, country
institution_tokeep <- data[data$institution_total >= 10,]
toplot <- data[data$institution %in% institution_tokeep$institution,]

calc <- toplot
calc$journal_total <- as.numeric(as.character(calc$journal_total))
calc$i_proportion <- calc$published / calc$institution_total
calc$j_proportion <- calc$journal_total / 32431
calc$diff <- calc$i_proportion / calc$j_proportion
calc <- calc[calc$published > 5,]
# minimum published preprints, journal
journal_tokeep <- aggregate(toplot$published, by=list(journal=toplot$journal), FUN=sum)
journal_tokeep <- journal_tokeep[journal_tokeep$x >= 30,]
toplot <- toplot[toplot$journal %in% journal_tokeep$journal,]
wide <- pivot_wider(toplot, names_from=c('journal'),
                    values_from=c('published'))
institutions <- wide$institution
wide$institution <- NULL
wide[is.na(wide)] <- 0
wide <- as.matrix(wide)
rownames(wide) <- institutions
prop <- prop.table(wide,margin=1)
x <- vegdist(prop, method="bray")
autoplot(cmdscale(x, eig = TRUE), label = TRUE)
plot(hclust(as.dist(x)))


# preprints per journal, institution level
data <- read.csv('preprints_per_journal_institution.csv')
data <- data[data$institution!='UNKNOWN',]
# minimum published preprints, country
institution_tokeep <- data[data$preprints >= 10,]
toplot <- data[data$institution %in% institution_tokeep$institution,]
toplot$prop <- toplot$preprints / toplot$journals


# STATEMENTS FROM PAPER

# comparing senior-author papers to whole-normalized preprint count
data=read.csv('preprints_per_country.csv')
cor.test(data$senior_author, data$complete_normalized)

# comparing proportion of preprints to proportion of authors
data=read.csv('overview_by_country.csv')
cor.test(data$authors, data$preprints_any_author, method="spearman")

# international collaboration correlations:
data=read.csv('overview_by_country.csv')
c <- ggplot(data=data, aes(x=international_papers_any_author, y=prop_international)) +
  geom_point() +
  scale_x_log10() +
  theme_bw() +
  labs(x='International preprints, any author', y='% papers international') +
  geom_smooth(method='lm', formula= y~x, se=FALSE)

cor.test(data$prop_international, data$seniorinter, method="spearman")
cor.test(data$seniorinter, data$international_papers_any_author, method="spearman")
cor.test(data$international_papers_any_author, data$prop_international, method="spearman")

# relationship between downloads and total papers:
library(plyr)
dloads <- read.csv('downloads_per_paper.csv')
dloads$counting <- 1 # so we can count papers per country
tokeep <- aggregate(dloads$counting, by=list(country=dloads$country), FUN=sum)
# only include senior countries with > 9 preprints listed
toplot <- dloads[dloads$country %in% tokeep[tokeep$x >= 70,]$country,]
medians <- ddply(toplot, .(country), summarise, med = median(downloads))
data <- medians %>% inner_join(tokeep, by=c("country"="country"))
colnames(data) <- c('country','downloads','papers')
cor.test(data$downloads, data$papers)

# relationship between publication rate and DOI assignment
doi <- read.csv('doi_rate.csv')
cor.test(doi$doi_rate, doi$pub_rate, method='pearson')

# downloads for international vs domestic preprints
data=read.csv('downloads_per_paper.csv')
mean(data[data$countries==1,]$downloads)
mean(data[data$countries>1,]$downloads)

# SUPPLEMENTAL FIGURES
# Authors per affiliation
data=read.csv('authors_per_affiliation.csv')
ggplot(data, aes(x=count)) +
  geom_histogram(bins=30) +
  scale_y_log10(labels=comma) +
  labs(x="Authors reporting affiliation", y="Affiliations") +
  theme_bw()

# distribution of authors per paper over time
authorcounts <- read.csv('authors_per_paper.csv')
colnames(authorcounts) <- c('id','year','authors')
ggplot(authorcounts, aes(x=authors)) +
  geom_histogram(bins=30) +
  scale_x_continuous(limits=c(0,100), oob = scales::squish) +
  scale_y_log10() +
  coord_cartesian() +
  #geom_vline(data=averages, aes(xintercept=harm), col='orange') +
  #geom_vline(data=averages, aes(xintercept=mean, color='yellow')) +
  facet_grid(rows=vars(year), scales='free_y') +
  theme_bw() +
  labs(x='Authors per preprint',y='Papers')

# PANEL: countries per paper over time
countrycounts <- read.csv('countries_per_author.csv')
countrycounts$year <- as.factor(countrycounts$year)
ggplot(countrycounts, aes(x=countries, group=year)) +
  geom_histogram(bins=10) +
  scale_x_continuous(limits=c(0.5,10.5), breaks=seq(0,10,1), expand=c(0,0), oob=scales::squish) +
  scale_y_log10() +
  theme_bw() + 
  facet_grid(rows=vars(year), scales='free_y')