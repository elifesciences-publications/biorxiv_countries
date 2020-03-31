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


#setwd('/Users/rabdill/code/biorxiv_authors/code/paper/data')
setwd('/Users/rabdill/code/biorxiv_authors/code/paper/final')
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
  matrix$country <- as.factor(matrix$country)
  return(matrix)
}


#---------------------------------
# FIGURE 1: preprints per country

# PANEL: map
data <- read.csv('overview_by_country.csv', header = TRUE, stringsAsFactors = FALSE) %>%
  select(alpha2, preprints_senior_author)
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

# PANEL: bar plot, preprints per country
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

# PANEL: Preprints per country, any author
overview <- read.csv('overview_by_country.csv') %>%
  select(country,preprints_any_author)
overview <- cleanup_countries(overview)
data <- data %>%
  left_join(overview, by=c("country"="country"))
data[data$country=='OTHER',]$preprints_any_author <- 25564

any <- ggplot(
  data=data,
  aes(x=reorder(country, running_total), y=preprints_any_author, fill=country)
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

# Assemble figure 1 with patchwork
plot_grid(time,
  plot_grid(senior, any, nrow=1,ncol=2, rel_widths=c(3,2),
    labels=c('c','d'), hjust = c(-0.65, 0.5), vjust=c(0.5, 0.5)
  ),
ncol=1, nrow=2, rel_heights=c(3,2), labels=c('b'))

# FIGURE 2: PREPRINT ENTHUSIASM
# panel - preprint enthusiasm
data <- read.csv('adjusted_preprints.csv')
data <- data[data$preprints>50,]
data <- cleanup_countries(data)
data$country <- as.character(data$country) 
data[data$country=='United States',]$country <- 'USA'
data[data$country=='United Kingdom',]$country <- 'UK'
data$country <- as.factor(data$country)

enthusiasm_top <- ggplot(data=data[1:10,], aes(x=reorder(country, proportion_ratio), y=proportion_ratio)) +
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

enthusiasm_bottom <- ggplot(data=data[36:45,], aes(x=reorder(country, proportion_ratio), y=proportion_ratio)) +
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


# panel - total preprints
preprints <- ggplot(data=toplot,
  aes(x=reorder(country, proportion_ratio), y=citable_docs, fill=continent, label=preprints)
) +
  geom_bar(stat="identity") +
  geom_text(aes(label=comma(citable_docs, accuracy=1), y=480000), hjust=0) +
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

# PANEL: scatterplot of enthusiasm
library(ggrepel)
data <- read.csv('adjusted_preprints.csv')
data <- cleanup_countries(data)
toplot <- data[data$preprints>=50,]
scatter <- ggplot(toplot) +
  geom_point(aes(x=citable_docs, y=proportion_ratio)) +
  geom_hline(yintercept=1, color='red', size=0.2) +
  geom_text_repel(
    aes(x=citable_docs, y=proportion_ratio, label=country),
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

# assemble figure

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

# FIGURE: Authors
authorcounts <- read.csv('authors_month.csv')
authorcounts$time <- ((12*(authorcounts$year - 2013))+authorcounts$month)-10

authormeans = data.frame(
  time=integer(), mean=double(), moving=double()
)
for(year in 2013:2019) {
  for(month in 1:12) {
    timestamp <- ((12*(year - 2013))+month-10)
    authormeans <- rbind(authormeans,
       c(timestamp,
         Hmean(authorcounts[authorcounts$time==timestamp,]$count),
         Hmean(authorcounts[authorcounts$time<=timestamp,]$count)
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
  #geom_smooth(se=FALSE, method="lm", size=0.75) +
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
plot(monthly_authors)

x <- cor.test(authormeans$time, authormeans$mean, method='pearson')


# PANEL: countries per paper, MONTHLY
countrycounts <- read.csv('countries_month.csv')
countrycounts$time <- ((12*(countrycounts$year - 2013))+countrycounts$month)-10

means = data.frame(
  time=integer(), mean=double(), moving=double()
)
for(year in 2013:2019) {
  for(month in 1:12) {
    timestamp <- ((12*(year - 2013))+month-10)
    means <- rbind(means,
                c(timestamp,
                  mean(countrycounts[countrycounts$time==timestamp,]$count),
                  mean(countrycounts[countrycounts$time<=timestamp,]$count)
                )
             )
  }
}
colnames(means) <- c('time','mean', 'moving')


monthly_country <- ggplot(means) +
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
plot(monthly_country)

plot_grid(monthly_authors, monthly_country, nrow=2, ncol=1, align='v')

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
plot_grid(monthly,
    plot_grid(countries_time, countrycount, nrow=1,ncol=2),
  nrow=2, ncol=1
)


# FIGURE: senior authors by country
data=read.csv('overview_by_country.csv')
# what proportion of a country's international preprints include a senior author from that country?
data$seniorinter <- data$international_papers_senior_author / data$international_papers_any_author
# what proportion of a country's preprints are international?
data$prop_international <- data$international_papers_any_author / data$preprints_any_author
# limit to countries with >= 30 international preprints
data <- data[data$international_papers_any_author >= 30,]
data <- data[!is.na(data$seniorinter),]

# PANEL: International senior authorship compared to total international papers
a <- ggplot(data=data, aes(x=international_papers_any_author, y=seniorinter)) +
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

# PANEL: senior author rate per country
monthframe=read.csv('preprints_country_time.csv')
data <- monthframe[monthframe$month=='2019-12',]
overview <- read.csv('overview_by_country.csv') %>%
  select(country,senior_author_rate_international)
overview <- cleanup_countries(overview)
data <- data %>%
  left_join(overview, by=c("country"="country"))

data[data$country=='OTHER',]$senior_author_rate_international <- 6994/16941
b <- ggplot(
  data=data,
  aes(x=reorder(country, senior_author_rate_international), y=senior_author_rate_international)
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
    legend.position = "none"
  )


# PANEL: contributor countries, by senior author
data=read.csv('contributor_country_senior_counts.csv')
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

compiled <- (a / b)
compiled <- compiled | c
compiled <- compiled + plot_layout(widths=c(1,2))
compiled + plot_annotation(
  tag_levels = 'a',
  tag_prefix = '(',
  tag_suffix = ')',
) & theme(plot.tag=element_text(face='bold'))

# using cowplot for this one because panels a and b shouldn't 
# be aligned on their left axis
plot_grid(
  plot_grid(
    a,b,ncol=1,nrow=2,align='r',labels=c('(a)','(b)')
  ),
  c, ncol=2, nrow=1, widths=c(1,2), labels=c('','(c)'), hjust=0.3
)

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
  geom_smooth(method='lm', se=FALSE, formula='y~x') +
  scale_x_continuous(
    limits=c(193,400),
    breaks=seq(200,400,50)
  ) +
  labs(x='Downloads per preprint', y='Publication rate') +
  theme_bw() +
  basetheme

# PANEL: median downloads per country and total preprints:
dloads <- read.csv('downloads_per_paper.csv')
counts <- read.csv('adjusted_preprints.csv')
medians <- ddply(dloads, .(country), summarise, med = median(downloads))
data <- medians %>% inner_join(counts, by=c("country"="country")) %>%
  select(country, med, preprints)
colnames(data) <- c('country','downloads','preprints')

dload_totals <- ggplot(data, aes(x=preprints, y=downloads)) +
  geom_point(size=3) +
  geom_smooth(method='lm', se=FALSE, formula='y~x') +
  scale_x_log10(labels=comma) +
  labs(x='Total preprints, senior author', y='Downloads per preprint') +
  theme_bw() +
  basetheme

# panel: publication rate
pubdata <- read.csv('overview_by_country.csv')
pubdata$pubrate <- pubdata$published_pre2019 / pubdata$senior_pre2019
tokeep <- pubdata[pubdata$preprints_senior_author >= 100,] %>% select(country,pubrate)
tokeep <- cleanup_countries(tokeep)
tokeep <- tokeep[!is.na(tokeep$country),]

pubrateplot <- ggplot(tokeep, aes(x=reorder(country,pubrate, reverse=TRUE), y=pubrate)) +
  geom_bar(stat="identity") +
  geom_hline(yintercept=sum(pubdata$published_pre2019)/sum(pubdata$senior_pre2019), color='red', size=1) + # overall
  labs(y='Proportion published', x='Country') +
  coord_flip() +
  theme_bw() +
  basetheme

built <- dloadplot | (dload_totals / pubdload) | pubrateplot
built +
  plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))


# EXTRA PANEL: reordering pubrate plot to be next to download plot
# panel: publication rate
data <- read.csv('overview_by_country.csv')
data$pubrate <- data$published_pre2019 / data$senior_pre2019
tokeep <- data[data$preprints_senior_author >= 100,] %>% select(country,pubrate)
tokeep <- cleanup_countries(tokeep)
tokeep <- tokeep[!is.na(tokeep$country),]

tokeep <- tokeep %>% inner_join(medians, by=c("country"="country"))

OTHERpubrateplot <- ggplot(tokeep, aes(x=reorder(country,med, reverse=TRUE), y=pubrate)) +
  geom_bar(stat="identity") +
  geom_hline(yintercept=sum(data$published_pre2019)/sum(data$senior_pre2019), color='red', size=1) + # overall
  labs(y='Proportion of preprints published', x='Country') +
  coord_flip() +
  scale_y_continuous(expand=c(0,0), limits=c(0,0.75)) +
  theme_bw() +
  basetheme +
  theme(
    axis.text.y = element_blank(),
    axis.title.y = element_blank()
  )
dloadplot | OTHERpubrateplot


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