# 00 LOAD PACKAGES --------------------------------------------------------

library(tidyverse)
library(lubridate)
library(gridExtra)
library(grid)

# 01 DOWNLOAD AND LOAD DATA -----------------------------------------------

# Setting working directory

# setwd("/home/qymera0/Documentos/Data Science/Learning/Johns_Hopkins_Coursera/Course_05_Reproducible_Research/Week04")

setwd("D:/Samuel/Meus Documentos/Google Drive/Data Science/Learning/Johns_Hopkins_Coursera/Course_05_Reproducible_Research/Week04")

# Download file

destfile <- "Dataset/tmp.bz2"

if (!file.exists(destfile)) {
        
        fileLink <- "https://d396qusza40orc.cloudfront.net/repdata%2Fdata%2FStormData.csv.bz2"
        
        download.file(fileLink, 
                      dest = destifile, 
                      method = "curl")
}

# Load data

weather <- read_csv("Dataset/tmp.bz2", 
                    col_types = cols(BGN_DATE = col_datetime(format = "%m/%d/%Y %H:%M:%S"), 
                                     BGN_TIME = col_time(format = "%H%M"), 
                                     CROPDMGEXP = col_character()))

# 02 DATA PREPARATION -----------------------------------------------------

# Select only columns of interest for whole analysis

weatherClean <- weather %>%
        select(BGN_DATE, BGN_TIME, EVTYPE, FATALITIES, INJURIES, PROPDMG, PROPDMGEXP, CROPDMG, CROPDMGEXP)

# Select rows for Question 01

fatalities <- weatherClean %>%
        select(BGN_DATE, EVTYPE, FATALITIES) %>%
        filter(FATALITIES > 0)

injuries <- weatherClean %>%
        select(BGN_DATE, EVTYPE, INJURIES) %>%
        filter(INJURIES > 0)


# Select rows for Question 2

economic <- weatherClean %>%
        select(BGN_DATE, EVTYPE, PROPDMG, PROPDMGEXP, CROPDMG, CROPDMGEXP)

table(economic$PROPDMGEXP)

table(economic$CROPDMGEXP)

# Change the variable type

economic <- economic %>%
        filter(grepl("m|k|b", PROPDMGEXP, ignore.case = TRUE)) %>%
        filter(grepl("m|k|b", CROPDMGEXP, ignore.case = TRUE))

economic$PROPDMGEXP <- str_replace_all(economic$PROPDMGEXP, 
                                       regex(c("k" = "1e+03", "m" = "1e+06", "b" = "1e+09"),
                                             ignore_case = TRUE))
        
economic$CROPDMGEXP <- str_replace_all(economic$CROPDMGEXP, 
                                       regex(c("k" = "1e+03", "m" = "1e+06", "b" = "1e+09"),
                                             ignore_case = TRUE))

economic <- economic %>%
        mutate(PROPDMGEXP = as.numeric(PROPDMGEXP),
                CROPDMGEXP = as.numeric(CROPDMGEXP))



# 03 ANSERING QUESTION 01 -------------------------------------------------

# Across the United States, which types of events are most harmful with respect to population health?

# Determine with fatalities are top 5

fatTop <- fatalities %>%
        group_by(EVTYPE) %>%
        summarise(fat.total = sum(FATALITIES)) %>%
        top_n(n = 5, wt = fat.total)

# Plot TOP 5 fatalities

fatTopPlot <- ggplot(fatTop, aes(x = EVTYPE, y = fat.total, fill = EVTYPE)) +
                geom_bar(stat = "identity") + 
                        labs(title = "",
                             subtitle = "Total count from 1950 to 2011",
                             y = "",
                             x = "") +
                        scale_fill_discrete(name = "Event type") +
                        theme_minimal() + 
                        theme(panel.border = element_blank(), 
                              panel.grid.major = element_blank(),
                              panel.grid.minor = element_blank(), 
                              axis.line = element_line(colour = "azure4"),
                              axis.title = element_text(colour = "azure4"),
                              axis.text = element_text(colour = "azure4"),
                              axis.text.x = element_blank(),
                              plot.title = element_text(colour = "azure4"),
                              plot.subtitle = element_text(colour = "azure4"),
                              strip.text = element_text(colour = "azure4"),
                              legend.text = element_text(colour = "azure4"),
                              legend.title = element_text(colour = "azure4", face = "bold"),
                              legend.position = "bottom")

# Summarise fatalities cause totals by event type and year

fatTime <- fatalities %>%
        group_by(EVTYPE, year(BGN_DATE)) %>%
        summarise(fat.total = sum(FATALITIES)) %>%
        filter(EVTYPE %in% fatTop$EVTYPE) %>%
        rename(fat.year = `year(BGN_DATE)`)

# Plot fatalities cause totals by event type and year

fYearSeries <- ggplot(fatTime, aes(x = fat.year, y = fat.total)) + 
                geom_line(aes(color = EVTYPE), size = 1) + 
                        labs(title = "",
                             subtitle = "Total count across years",
                             y = "",
                             x = "") +
                scale_color_discrete(name = "Event Type") +
                        theme_minimal() + 
                        theme(panel.border = element_blank(), 
                              panel.grid.major = element_blank(),
                              panel.grid.minor = element_blank(), 
                              axis.line = element_line(colour = "azure4"),
                              axis.title = element_text(colour = "azure4"),
                              axis.text = element_text(colour = "azure4"),
                              plot.title = element_text(colour = "azure4"),
                              plot.subtitle = element_text(colour = "azure4"),
                              legend.text = element_text(colour = "azure4"),
                              legend.title = element_text(colour = "azure4", face = "bold"),
                              legend.position = "bottom")

# Share the same legend bewteen graphics function

g_legend <- function(a.gplot) {
        
        tmp <- ggplot_gtable(ggplot_build(a.gplot))
        
        leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
        
        legend <- tmp$grobs[[leg]]
        
        return(legend)
        
}

# Get fatTopPlot legend

fatLegend <- g_legend(fatTopPlot)

grid.arrange(arrangeGrob(fatTopPlot + theme(legend.position = "none"),
                         fYearSeries + theme(legend.position = "none"),
                         nrow = 1),
             fatLegend, 
             nrow = 2, 
             heights = c(10, 1),
             top = textGrob(label = "TOP 5 fatalities causes in USA",
                            gp = gpar(col = "azure4", fontface = "bold", cex = 1.5),
                            hjust = -0.1,
                            vjust = 0.5,
                            x = 0,
                            y = 0))

# Determine Injuries

# Determine with fatalities are top 5

injTop <- injuries %>%
        group_by(EVTYPE) %>%
        summarise(inj.total = sum(INJURIES)) %>%
        top_n(n = 5, wt = inj.total)

# Plot TOP 5 injuries

injTopPlot <- ggplot(injTop, aes(x = EVTYPE, y = inj.total, fill = EVTYPE)) +
        geom_bar(stat = "identity") + 
        labs(title = "",
             subtitle = "Total count from 1950 to 2011",
             y = "",
             x = "") +
        scale_fill_discrete(name = "Event type") +
        theme_minimal() + 
        theme(panel.border = element_blank(), 
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(), 
              axis.line = element_line(colour = "azure4"),
              axis.title = element_text(colour = "azure4"),
              axis.text = element_text(colour = "azure4"),
              axis.text.x = element_blank(),
              plot.title = element_text(colour = "azure4"),
              plot.subtitle = element_text(colour = "azure4"),
              strip.text = element_text(colour = "azure4"),
              legend.text = element_text(colour = "azure4"),
              legend.title = element_text(colour = "azure4", face = "bold"),
              legend.position = "bottom")


# Summarise injuries cause totals by event type and year

injTime <- injuries %>%
        group_by(EVTYPE, year(BGN_DATE)) %>%
        summarise(inj.total = sum(INJURIES)) %>%
        filter(EVTYPE %in% injTop$EVTYPE) %>%
        rename(inj.year = `year(BGN_DATE)`)

# Plot injuries cause totals by event type and year

iYearSeries <- ggplot(injTime, aes(x = inj.year, y = inj.total)) + 
        geom_line(aes(color = EVTYPE), size = 1) + 
        labs(title = "",
             subtitle = "Total count across years",
             y = "",
             x = "") +
        scale_color_discrete(name = "Event Type") +
        theme_minimal() + 
        theme(panel.border = element_blank(), 
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(), 
              axis.line = element_line(colour = "azure4"),
              axis.title = element_text(colour = "azure4"),
              axis.text = element_text(colour = "azure4"),
              plot.title = element_text(colour = "azure4"),
              plot.subtitle = element_text(colour = "azure4"),
              legend.text = element_text(colour = "azure4"),
              legend.title = element_text(colour = "azure4", face = "bold"),
              legend.position = "bottom")

# Get injTopPlot legend

injLegend <- g_legend(injTopPlot)


grid.arrange(arrangeGrob(injTopPlot+ theme(legend.position = "none"),
                         iYearSeries + theme(legend.position = "none"),
                         nrow = 1),
             injLegend, 
             nrow = 2, 
             heights = c(10, 1),
             top = textGrob(label = "TOP 5 injuries causes in USA",
                            gp = gpar(col = "azure4", fontface = "bold", cex = 1.5),
                            hjust = -0.1,
                            vjust = 0.5,
                            x = 0,
                            y = 0))

# 04 ANSWERING QUESTION 02 ------------------------------------------------

# Across the United States, which types of events have the greatest economic consequences?

# Determine with ecnomic damages causes are top 5

ecoTop <- economic %>%
        mutate(tDmg = (CROPDMG * CROPDMGEXP + PROPDMG * PROPDMGEXP)/1000000000) %>%
        group_by(EVTYPE) %>%
        summarise(dmg.total = sum(tDmg)) %>%
        top_n(n = 5, wt = dmg.total)

# Plot TOP 5 ecnomic damages causes

ecoTopPlot <- ggplot(ecoTop, aes(x = EVTYPE, y = dmg.total, fill = EVTYPE)) +
        geom_bar(stat = "identity") + 
        labs(title = "",
             subtitle = "Total sum from 1950 to 2011 in Billions of USD$",
             y = "",
             x = "") +
        scale_fill_discrete(name = "Event type") +
        theme_minimal() + 
        theme(panel.border = element_blank(), 
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(), 
              axis.line = element_line(colour = "azure4"),
              axis.title = element_text(colour = "azure4"),
              axis.text = element_text(colour = "azure4"),
              axis.text.x = element_blank(),
              plot.title = element_text(colour = "azure4"),
              plot.subtitle = element_text(colour = "azure4"),
              strip.text = element_text(colour = "azure4"),
              legend.text = element_text(colour = "azure4"),
              legend.title = element_text(colour = "azure4", face = "bold"),
              legend.position = "bottom")

# Summarise economic damage cause totals by event type and year

ecoTime <- economic %>%
        mutate(tDmg = (CROPDMG * CROPDMGEXP + PROPDMG * PROPDMGEXP) / 1000000000) %>%
        group_by(EVTYPE, year(BGN_DATE)) %>%
        summarise(eco.total = sum(tDmg)) %>%
        filter(EVTYPE %in% ecoTop$EVTYPE) %>%
        rename(eco.year = `year(BGN_DATE)`)

# Plot economic damage cause totals by event type and year

eYearSeries <- ggplot(ecoTime, aes(x = eco.year, y = eco.total)) + 
        geom_line(aes(color = EVTYPE), size = 1) + 
        labs(title = "",
             subtitle = "Total sum in Billions of USD$",
             y = "",
             x = "") +
        scale_color_discrete(name = "Event Type") +
        theme_minimal() + 
        theme(panel.border = element_blank(), 
              panel.grid.major = element_blank(),
              panel.grid.minor = element_blank(), 
              axis.line = element_line(colour = "azure4"),
              axis.title = element_text(colour = "azure4"),
              axis.text = element_text(colour = "azure4"),
              plot.title = element_text(colour = "azure4"),
              plot.subtitle = element_text(colour = "azure4"),
              legend.text = element_text(colour = "azure4"),
              legend.title = element_text(colour = "azure4", face = "bold"),
              legend.position = "bottom")

# Get fatTopPlot legend

ecoLegend <- g_legend(ecoTopPlot)


grid.arrange(arrangeGrob(ecoTopPlot+ theme(legend.position = "none"),
                         eYearSeries + theme(legend.position = "none"),
                         nrow = 1),
             ecoLegend, 
             nrow = 2, 
             heights = c(10, 1),
             top = textGrob(label = "TOP 5 ecnomic damage causes in USA",
                            gp = gpar(col = "azure4", fontface = "bold", cex = 1.5),
                            hjust = -0.1,
                            vjust = 0.5,
                            x = 0,
                            y = 0))

