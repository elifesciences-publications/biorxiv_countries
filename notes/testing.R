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

library(rworldmap) # for map of preprints


#setwd('/Users/rabdill/code/biorxiv_authors/code/paper/data')
setwd('/Users/rabdill/code/biorxiv_authors/code/paper')
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



# FIGURE 1
data <- read.csv('supp_table01.csv', header = TRUE, stringsAsFactors = FALSE) %>%
  select(alpha2, senior_author)
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

# FIGURE 1B
data <- monthframe[monthframe$month=='2019-12',]

senior <- ggplot(
  data=data,
  aes(x=reorder(country, running_total), y=running_total, fill=country)
) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0), breaks=seq(0,30000,8000), labels=comma) +
  coord_flip(ylim=c(0,28000)) +
  labs(x = "", y = "Preprints, senior author") +
  theme_bw() +
  scale_fill_brewer(palette = 'Set1', guide='legend',
                    aesthetics = c('color','fill')) +
  basetheme +
  theme(
    legend.position = "none",
    plot.margin = unit(c(2,0.2,1,1), "lines")
  )

# FIGURE 1C
data <- read.csv('supp_table01.csv')
data <- cleanup_countries(data[1:8,])
data$country <- as.character(data$country)
data <- rbind(data, data.frame(alpha2=NA, country='OTHER',senior_author=10000,any_author=25331)) # dummy value for "senior author"
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

# FIGURE 1D
monthframe=read.csv('preprints_over_time.csv')
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

# Compiling figure 1
plot_grid(
  plot_grid(senior, any, nrow=1,ncol=2, rel_widths=c(4,3),
            labels=c('(b)','(c)'), hjust = c(-0.65, 0.5)
  ),
  time,
  ncol=1, nrow=2, rel_heights=c(2,3), labels=c('','(d)'))


# FIGURE 2: Enthusiasm
data <- read.csv('supp_table02.csv')
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

# only reduce the list AFTER calculating enthusiasm so the total citable documents includes everyone
data <- data[data$senior_author_preprints>=50,]

# panel 2A
# PANEL: scatterplot of enthusiasm
library(ggrepel)

# we need an "enthusiasm=1" line to draw through the plot, but
# it's trickier to define with the log scales so this thing just
# defines the endpoints of the line:
oneline <- data.frame(x=c(243.1, 16495865), y=c(1,67855))
scatter <- ggplot() +
  geom_point(data=data, aes(x=citable_total, y=senior_author_preprints)) +
  geom_line(data=oneline, aes(x=x, y=y), color='red') +
  geom_text_repel(
    data=data,
    aes(x=citable_total, y=senior_author_preprints, label=country),
    size=4,
    segment.size = 0.5,
    segment.color = "grey50",
    point.padding = 0.2,
    max.iter = 5000
  ) +
  scale_x_log10(labels=comma) +
  scale_y_log10(labels=comma) +
  coord_cartesian(xlim=c(11400,2900000), ylim=c(48,25500)) +
  labs(x='Citable documents', y='Senior-author preprints') +
  theme_bw() +
  basetheme

# figure 2, plot 2:
enthusiasm_top <- ggplot(data=top_n(data, 10, enthusiasm),
        aes(x=reorder(country, enthusiasm) ,y=enthusiasm)) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0)) +
  coord_flip(ylim=c(0,2.3)) +
  labs(x = "", y = "") +
  theme_bw() +
  basetheme +
  theme(
    axis.text.x = element_blank(),
    plot.margin = unit(c(0,1,-1,0), "lines"),
    axis.ticks.x = element_blank(),
    panel.grid.minor = element_blank()
  )

# panel 2, plot 3
enthusiasm_bottom <- ggplot(data=top_n(data, -10, enthusiasm), aes(x=reorder(country, enthusiasm), y=enthusiasm)) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0)) +
  coord_flip(ylim=c(0,2.3)) +
  labs(x = "", y = "bioRxiv enthusiasm") +
  theme_bw() +
  basetheme +
  theme(
    plot.margin = margin(0,1,0,0),
    panel.grid.minor = element_blank()
  )


# compile figure 2
right <- enthusiasm_top + labs(tag='(b)') + textGrob('(24 other countries...)', gp=gpar(fontface='italic')) + enthusiasm_bottom +
  plot_layout(nrow=3, heights=c(60,1,60))

scatter + labs(tag='(a)') + right + plot_layout(ncol=2, widths=c(4,1)) & theme(plot.tag=element_text(face='bold'))

#z <- left - (scatter + labs(tag='(a)'))
#z + plot_layout(ncol=2, widths=c(1,4)) & theme(plot.tag=element_text(face='bold'))




# FIGURE 3: contributor countries

data <- read.csv('supp_table03.csv')
data <- cleanup_countries(data)

# figure out overall rates
# senior author rate
overall.sen_rate <- sum(data$intl_senior_author) / sum(data$intl_any_author)
# international collab rate
overall.intl_rate <- sum(data$intl_any_author) / sum(data$all_any_author)
# total preprints
overall.intl_any <- median(data$intl_any_author)

data <- data[(data$contributor=='TRUE'),]

# add other countries for comparison
top <- read.csv('supp_table03.csv')
top <- top_n(top[top$intl_any_author > 50,], 5, intl_senior_rate)

data <- rbind(data, top)
data <- cleanup_countries(data)
manual_fill <- scale_fill_manual(values=c("#999999","#E41A1C")) 
# panel 3b
senior_rate <- ggplot(data, aes(x=reorder(country, -intl_senior_rate), y=intl_senior_rate, fill=contributor)) +
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
# panel 3c
intl_rate <- ggplot(data, aes(x=reorder(country, -intl_senior_rate), y=intl_collab_rate, fill=contributor)) +
  geom_bar(stat="identity") +
  geom_hline(yintercept=overall.intl_rate, linetype=2) +
  coord_flip() +
  scale_y_continuous(expand=c(0,0), limits=c(0, 1.05), labels=label_percent(accuracy=1)) +
  labs(x='', y='International collaboration rate') +
  manual_fill +
  theme_bw() +
  basetheme +
  theme(
    legend.position = 'none',
    axis.text.y = element_blank()
  )
# panel 3d
total <- ggplot(data, aes(x=reorder(country, -intl_senior_rate), y=intl_any_author, fill=contributor)) +
  geom_bar(stat="identity") +
  coord_flip() +
  labs(x='', y='International preprints (any author)') +
  scale_y_continuous(expand=c(0,0), labels=comma) +
  manual_fill +
  theme_bw() +
  basetheme +
  theme(
    legend.position = 'none',
    axis.text.y = element_blank()
  )
# compile panels B through D:
plot_grid(
  senior_rate, intl_rate, total,
  ncol=3, nrow=1, labels=c('(b)','(c)','(d)'),
  hjust=c(-0.75, 0, 0), rel_widths=c(11,8,8))

# Contributor country patterns
data <- read.csv('supp_table03.csv')
data <- cleanup_countries(data)
data <- data[data$intl_any_author >= 50,]

# Senior author rate, total papers:
cor.test(data$intl_senior_rate, data$intl_any_author, method="spearman")
# Total papers, international collaboration rate
cor.test(data$intl_any_author, data$intl_collab_rate, method="spearman")
# International senior author rate and international collaboration rate:
cor.test(data$intl_collab_rate, data$intl_senior_rate, method="spearman")

# Panel 3a:  MAP of contributors
toplot <- data <- data[data$contributor=='TRUE',]
toplot <- joinCountryData2Map(data, joinCode = "ISO2",
                              nameJoinColumn = "alpha2",  mapResolution = "coarse", verbose=TRUE)

# chop off antarctica
toplot <- subset(toplot, continent != "Antarctica")

map <- mapCountryData(toplot, nameColumnToPlot = "contributor",
                      catMethod = "logFixedWidth", numCats=6,
                      xlim = NA, ylim = NA, mapRegion = "world",
                      colourPalette = "heat", addLegend = FALSE, borderCol = "black",
                      mapTitle = "",
                      oceanCol = NA, aspect = 1,
                      missingCountryCol = NA, add = FALSE,
                      lwd = 0.5)





# FIGURE 4
data <- read.csv('supp_table03.csv')
data <- cleanup_countries(data)
# limit to countries with >= 30 international preprints
data <- data[data$intl_any_author>30,]

# Figure 4a: International senior authorship compared to total international papers
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

# Figure 4b: international senior author rate per country
# *tk NOT ADDED TO REPRODUCTION DOC YET
b <- ggplot(
  data=data,
  aes(x=reorder(country, intl_senior_rate),
      y=intl_senior_rate, fill=as.factor(contributor))
) +
  geom_bar(stat="identity") +
  scale_y_continuous(expand=c(0,0)) +
  coord_flip(ylim=c(0,0.52)) +
  scale_fill_manual(values=c('#000000','red')) +
  labs(x = "Country", y = "Senior author rate, international preprints") +
  theme_bw() +
  basetheme +
  theme(
    legend.position = "none"
  )

# Figure 3e: alluvial plot of collaborator countries
data=read.csv('supp_table04.csv')
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
colors <- c(rep('white',18), "#999999","#F781BF","#A65628","#FFFF33","#FF7F00","#984EA3","#4DAF4A","#377EB8","#E41A1C")
# only include senior countries with > 25 preprints listed

ggplot(toplot, aes(y = count, axis1=contributor, axis2=senior)) +
  geom_alluvium(aes(fill=senior), width = 1/12, alpha=0.65) +
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

# Compiling figure 4
compiled <- (a / grid::textGrob('something cool here'))
compiled <- compiled | c
compiled <- compiled + plot_layout(widths=c(1,2))
compiled + plot_annotation(
  tag_levels = 'a',
  tag_prefix = '(',
  tag_suffix = ')',
) & theme(plot.tag=element_text(face='bold'))


# FIGURE 6

# Figure 6a: downloads per preprint per country
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

median(toplot[toplot$country=='Taiwan',]$downloads)
# Figure 6b: Publication rate and total preprints

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

# Figure 6c: Median downloads against publication rate

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
  labs(x='Downloads per preprint', y='Publication rate') +
  theme_bw() +
  basetheme

# Figure 6d: publication rate
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

# Compiling Figure 6
built <- dloadplot | (dload_totals / pubdload) | pubrateplot
built +
  plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))



# FIGURE 5: Country/journal links:
fishertest.odds <- function(row) {
  contingency <- c(
    row$preprints, # country in journal
    row$journaltotal - row$preprints, # total in journal (without country)
    row$countrytotal - row$preprints, # country not in journal
    23102 - row$journaltotal # no total outside of journal (without country)
  )
  contingency <- matrix(contingency, nrow = 2,
                        dimnames = list(collaborator = c("Country", "NoCountry"),
                                        senior = c("Journal", "NoJournal")))
  #print(contingency)
  fishtest <- fisher.test(contingency, alternative = "greater")
  return(fishtest$estimate)
}
fishertest.p <- function(row) {
  contingency <- c(
    row$preprints, # country in journal
    row$journaltotal - row$preprints, # total in journal (without country)
    row$countrytotal - row$preprints, # country not in journal
    23102 - row$journaltotal # no total outside of journal (without country)
  )
  contingency <- matrix(contingency, nrow = 2,
                        dimnames = list(collaborator = c("Country", "NoCountry"),
                                        senior = c("Journal", "NoJournal")))
  #print(contingency)
  fishtest <- fisher.test(contingency, alternative = "greater")
  return(fishtest$p.value)
}
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

# Supplementary Table 9:
table <- jlinks[jlinks$padj <= 0.05,] %>% select(country, journal, preprints, expected, p, padj, journaltotal, countrytotal)

# FIGURE 5a: preprints per journal, USA
newplot <- jlinks[jlinks$country=='United States',]
newplot$over <- (newplot$preprints - newplot$expected)/newplot$expected
newplot <- newplot[newplot$expected >= 30,]
ggplot(newplot, aes(x=reorder(journal,over), y=over, fill=(newplot$padj <= 0.05))) +
  geom_bar(stat='identity') +
  geom_text(aes(x=reorder(journal,over), y=ifelse(newplot$over > 0, -0.01, 0.01), label=journal),
            hjust=ifelse(newplot$over > 0, 1, 0)) +
  geom_hline(yintercept=0, color='black',size=1) +
  coord_flip() +
  scale_y_continuous(limits=c(-0.5, 0.77), breaks=seq(-0.5, 0.75, 0.25), expand=c(0,0)) +
  labs(y='Overrepresentation of United States',x='Journal') +
  theme_bw() +
  basetheme +
  scale_fill_manual(values=c('#999999','red')) +
  theme(
    legend.position='none',
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
  )

# FIGURE 5b: Country/journal links
library(tidyr)
library(corrplot)
# first, build matrix of p-values
pdata <- jlinks %>% select(country, journal, padj)

# filter by p value:
# first find journals with at least one link
tokeep.journal <- pdata[pdata$padj <= 0.05,]$journal
pdata <- pdata[pdata$journal %in% tokeep.journal,]
# then countries with at least one link
tokeep.country <- pdata[pdata$padj <= 0.05,]$country
pdata <- pdata[pdata$country %in% tokeep.country,]

pdata <- spread(pdata, country, padj)
rownames(pdata) <- as.character(pdata$journal)

# then build matrix of journal/country preprint counts
countdata <- jlinks %>% select(country, journal, preprints)
countdata <- countdata[countdata$journal %in% tokeep.journal,]
countdata <- countdata[countdata$country %in% tokeep.country,]
countdata <- spread(countdata, country, preprints)
rownames(countdata) <- as.character(countdata$journal)

count_sig <- function(x) {
  if(is.na(x)) return(0)
  if(x <= 0.05) {
    return(1)
  }
  return(0)
}
linkcounter <- pdata
linkcounter$journal <- NULL
linkcounter <- as.data.frame(apply(linkcounter, 1:2, count_sig))
journallinks <- as.data.frame(rowSums(linkcounter))
journallinks$journal <- rownames(journallinks)
rownames(journallinks) <- NULL
colnames(journallinks) <- c('links','journal')

# add null counts to matrix and sort by them
countdata <-  countdata %>% inner_join(journallinks, by=c("journal"="journal"))
countdata <- countdata %>% arrange(-links)
rownames(countdata) <- as.character(countdata$journal)

countrylinks <- as.data.frame(colSums(linkcounter))
countrylinks$country <- rownames(countrylinks)
rownames(countrylinks) <- NULL
colnames(countrylinks) <- c('links','country')
countrylinks <- countrylinks %>% arrange(-links)

pdata <-  pdata %>% inner_join(journallinks, by=c("journal"="journal"))
pdata <- pdata %>% arrange(-links)
rownames(pdata) <- as.character(pdata$journal)

countdata$journal <- NULL
countdata$links <- NULL
pdata$journal <- NULL # chop off column with journal names
pdata$links <- NULL
# make all the empty cells "insignificant"
pdata[is.na(pdata)] <- 1
countdata[is.na(countdata)] <-15 # workaround for bug (ONLY USE IF WE DON'T DISPLAY NON-SIGNIFICANT NUMBERS)

redblue <- colorRampPalette(c('yellow','yellow','red'))

countplot <- as.matrix(countdata[countrylinks$country])
pplot <- as.matrix(pdata[countrylinks$country])
corrplot(countplot,
  method='shade', is.corr = FALSE, insig='blank', addgrid.col='grey',
  sig.level = .05, col=redblue(50), na.label=NULL,
  p.mat=pplot)





# LESS AWFUL HEAT MAP
new <- jlinks %>% select(country, journal, preprints, padj)
tokeep.journal <- new[new$padj <= 0.05,]$journal
tokeep.country <- new[new$padj <= 0.05,]$country
new <- new[new$country %in% tokeep.country,]
new <- new[new$journal %in% tokeep.journal,]
new$padj.size <- (1-new$padj)

ggplot(new, aes(x=country,y=journal, fill=preprints,  height=padj.size,  width=padj.size)) + 
  geom_tile()+
  #scale_fill_brewer(palette = 'Set1', guide='legend', aesthetics = c('color','fill')) +
  scale_fill_distiller(palette = "Reds", direction=1) +
  #scale_color_distiller(palette = "RdYlGn", direction=1, limits=c(0,1),name="q-value") +
  #scale_x_continuous("variable", breaks = seq_len(m), labels = colnames(nba)) +
  #scale_y_continuous("variable", breaks = seq_len(m), labels = colnames(nba), trans="reverse") +
  coord_fixed() + # to keep the tiles square
  theme(axis.text.x=element_text(angle=45, vjust=1, hjust=1),
        panel.background=element_blank(),
        #panel.grid.minor=element_blank(),
        #panel.grid.major=element_blank(),
  )
asdf







# STATEMENTS FROM PAPER:
# correlation of different counting methods:
counts <- read.csv('supp_table06.csv')
x <- cor.test(counts$cn_total, counts$whole_count)
x$p.value


# TESTING SENIOR AUTHORS OF CONTRIBUTOR COUNTRIES
papers <- read.csv('senior_authors.csv')
papers <- cleanup_countries(papers) # note: this ONLY standardizes the contributor countries, not the senior-author ones
contributors <- c('Uganda', 'Vietnam', 'Tanzania', 'Croatia', 'Slovakia', 'Indonesia', 'Thailand', 'Greece', 'Kenya', 'Bangladesh', 'Egypt', 'Ecuador', 'Estonia', 'Peru', 'Turkey', 'Czechia', 'Colombia', 'Iceland')
seniors <- c('United States of America','United Kingdom of Great Britain and Northern Ireland','Switzerland','Sweden','Netherlands','Germany','France','Canada','Australia')

totals <- read.csv('supp_table03.csv') # international preprints per country
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
     dimnames = list(collaborator = c("Contrib", "NoContrib"),
                    senior = c("AUS", "NoAUS")))
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
combos$padj <- p.adjust(combos$p, method='BH')
combos$padj <- combos$p * length(combos$contributor)


# Figure S2: Contributor country correlations
data <- read.csv('supp_table03.csv')
data <- cleanup_countries(data)
data <- data[data$intl_any_author>30,]

cor.test(data$intl_senior_rate, data$intl_any_author, method="spearman")
cor.test(data$intl_any_author, data$intl_collab_rate, method="spearman")
cor.test(data$intl_collab_rate, data$intl_senior_rate, method="spearman")

data <- read.csv('supp_table03.csv')
data <- cleanup_countries(data)
# limit to countries with >= 30 international preprints

# Figure 4a: International senior authorship compared to total international papers
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

fig <- a | b | c
fig + plot_annotation(
    tag_levels = 'a',
    tag_prefix = '(',
    tag_suffix = ')',
  ) & theme(plot.tag=element_text(face='bold'))


# FIGURE S1: collaborators per paper

# panel S1a:
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
  geom_smooth(method='lm', color='red', size=0.3, se=FALSE) +
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

x <- cor.test(authormeans$time, authormeans$mean, method='pearson')

# panel S1b: countries per paper
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


# compiling figure S1:
plot_grid(monthly_authors, monthly_country,
          nrow=2, ncol=1, align='v', labels=c('(a)','(b)'))

