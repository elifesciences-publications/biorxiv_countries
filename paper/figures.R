library(ggplot2)
library(plyr)
library(DescTools) # for harmonic mean
library(rworldmap) # for map of preprints

setwd('/Users/rabdill/code/biorxiv_authors/code/paper/data')


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
    nameJoinColumn = "country",  mapResolution = "course", verbose=FALSE)

# if you want to adjust for country population:
#toplot$value <- toplot$value / toplot$POP_EST

mapCountryData(toplot, nameColumnToPlot = "value",
   catMethod = "quantiles", numCats=10,
   xlim = NA, ylim = NA, mapRegion = "world",
   colourPalette = "heat", addLegend = TRUE, borderCol = "grey",
   mapTitle = "Preprints per country", oceanCol = NA, aspect = 1,
   missingCountryCol = NA, add = FALSE,
   lwd = 0.5)
