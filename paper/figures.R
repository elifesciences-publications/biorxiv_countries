library(ggplot2)
library(cowplot) # for combining figures
require(scales) # for axis labels
library(grid)
library(ggthemes)# for pretty

library(plyr)
library(DescTools) # for harmonic mean
library(rworldmap) # for map of preprints

setwd('/Users/rabdill/code/biorxiv_authors/code/paper/data')

themepurple = "#d0c1ff"
themeorange = "#ffab03"
themedarkgrey = "#565656"

themedarktext = "#707070"
big_fontsize = unit(12, "pt")

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



#---------------------------------

# Papers per country over time
monthframe=read.csv('preprints_country_time.csv')
x <- ggplot(monthframe, aes(x=month, y=running_total,
                            group=country, color=country, fill=country)) +
  geom_bar(position="fill", stat="identity") +
  labs(x = "", y = "Cumulative preprints") +
  theme_bw() +
  theme(
    axis.text.x=element_blank(),
    legend.position="bottom"
  )

x <- add_year_x(x, TRUE, -0.01)
plot(x)




# FIGURE: Authors per paper
data <- read.csv('authors_per_paper.csv')
colnames(data) <- c('id','year','authors')

harms <- vector("list", 7)
lower <- vector("list", 7)
upper <- vector("list", 7)
i <- 1
for(year in seq(2013,2019,1)) {
  calc <- Hmean(data[data$year==year,]$authors, conf.level=0.95)
  harms[[i]] <- calc[['mean']]
  lower[[i]] <- calc[['lwr.ci']]
  upper[[i]] <- calc[['upr.ci']]
  i <- i + 1
}

toplot <- data.frame(
  year = seq(2013,2019,1),
  harm = unlist(harms, use.names=FALSE),
  lower = unlist(lower, use.names=FALSE),
  upper = unlist(upper)
)
ggplot(toplot, aes(x=year, y=harm)) +
  geom_line() +
  scale_x_continuous(breaks=seq(2013, 2019, 1)) +
  labs(x='Year', y='Authors per paper')


# FIGURE: map of preprints per country
data <- read.csv('preprints_country_all.csv', header = TRUE, stringsAsFactors = FALSE)
colnames(data) <- c('country','value')
toplot <- joinCountryData2Map(data, joinCode = "ISO2",
    nameJoinColumn = "country",  mapResolution = "coarse", verbose=FALSE)

mapCountryData(toplot, nameColumnToPlot = "value",
   catMethod = "logFixedWidth", numCats=5,
   xlim = NA, ylim = NA, mapRegion = "world",
   colourPalette = "heat", addLegend = TRUE, borderCol = "grey",
   mapTitle = "Preprints per country", oceanCol = NA, aspect = 1,
   missingCountryCol = NA, add = FALSE,
   lwd = 0.5)

# FIGURE: Authors per affiliation
data=read.csv('authors_per_affiliation.csv')
ggplot(data, aes(x=count)) +
  geom_histogram() +
  scale_y_log10(labels=comma) +
labs(x="authors reporting affiliation", y="affiliations")
