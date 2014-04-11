#This file will clean dirty data and play with it
    #We will learn regular expresions, 
    #package reshape to manipulate data
    #and dplyr to explore/transform data.


#load libraries----
library(reshape)
library(dplyr)

#load data----
dat <- read.csv("example/dirty_data.csv")
str(dat)

#First we notice wierd columns...Get rid of columns with no data... The X's columns----
dat <- dat[,1:16]
str(dat)

#Second thing we notice is Date is a factor----
levels(dat$Date)
#lets make it a date
dat$Date <- as.Date(dat$Date, format= "%d/%m/%Y")
str(dat)
#you may want to extract only the day (or month)
#Is better to use POSIXlt for that, which splits the date in days/months/year for you
dat$Date2 <- as.POSIXlt(dat$Date)
dat$Date2$mday
#see DateTimeClasses {base} for more options
str(dat)

# You notice CoVariate is Factor, but should be numeric----
levels(dat$CoVariate)
#NA was bady coded, converting it to numeric will force non numbers to be NA's
#Note as.numeric(dat$CoVariate) will use level number (1 to 36)
dat$CoVariate <- as.numeric(as.character(dat$CoVariate))
str(dat)

#Same with Genus.species7?----
levels(dat$Genus.species7)
#not quite... let's assume we decide we want to use value = 7
levels(dat$Genus.species7)[which(levels(dat$Genus.species7) == "6 (+1)")] <- 7
ifelse(levels(dat$Genus.species7) == "6 (+1)", 7, levels(dat$Genus.species7))
    levels(dat$Genus.species7)
#now we can convert to numeric
dat$Genus.species7 <- as.numeric(as.character(dat$Genus.species7))
str(dat)

#Again with sp11?----
levels(dat$Genus.species11)
levels(dat$Genus.species11)[which(levels(dat$Genus.species11) == "9 or 4")] <- 4
    #let's say we checked the original field notes
levels(dat$Genus.species11)
#now we can convert to numeric
dat$Genus.species11 <- as.numeric(as.character(dat$Genus.species11))
str(dat)

#ready? lets check the levels/value ranges----
levels(dat$Site)
#how many times "B(edge)" happens?
table(dat$Site) #ok, then ignore.
#but wait...one D? 11 B? D is a typo
levels(dat$Site)  <- c("A", "B", "B", "C", "B")

levels(dat$Treatment) #blank spaces are killing us.
#we can fix that one as before, but when you have 200 levels you need to automatize it.
#we will use regular expresions.
levels(dat$Treatment) <- gsub(pattern= " ", "", levels(dat$Treatment))

range(dat$CoVariate, na.rm = TRUE) #seems correct
                             
#let's ignore for now the species and format the data as tidy data----
#we use library reshape

dat_melted <- melt(data = dat[,-17], id.vars= c("Site", "Treatment", "Date", "CoVariate"))
str(dat_melted) #note Date 2 is ignored in the [,-17]
colnames(dat_melted)[c(5,6)] <- c("Genus_sp", "counts")
head(dat_melted)

#now continue checking range of counts----
range(dat_melted$counts, na.rm = TRUE)
#!!
#imposible numbers:
dat_melted$counts[which(dat_melted$counts < 0)]
#let's assume is 3 and is a typo
dat_melted$counts[which(dat_melted$counts < 0)] <- 3
#improbable numbers:
fivenum(dat_melted$counts)
dat_melted$counts[which(dat_melted$counts > 100)]
dat_melted[which(dat_melted$counts > 100),]
boxplot(dat_melted$counts)
dat_melted$counts[which(dat_melted$counts > 500)] <- NA
boxplot(dat_melted$counts) #lets keep it as an outlyer
str(dat_melted) #why counts not integer?
as.integer(dat_melted$counts) #may be we are scriwing up something?
#My first approach... now how many have end in .0
#I tried regexp
#grep("[0]$", dat_melted$counts, value = TRUE) #fails becasue R internally 
    #does as.character(dat_melted$counts) and removes zeros... more on regexp below
#I can convert it to character first unelegantly...
#temp <- as.character(dat_melted$counts)
#grep("[.]", temp, value = TRUE)

#better option after talking with R expert
#make a relatively complex function
#probable.integer <- function(x) abs(x - round(x)) < sqrt(.Machine$double.eps)
# .Machine tells you the smallest positive floating-point my R can handle.
#probable.integer(dat_melted$counts)
#dat_melted$counts[probable.integer(dat_melted$counts) == FALSE] 
#even better ater talking with The expert!
dat_melted$counts[round(dat_melted$counts) != dat_melted$counts] 

# I assume is 88
dat_melted$counts[which(dat_melted$counts == 8.8)] <- 88

#last, let's play with species names
levels(dat_melted$Genus_sp)
#I like _ better than .
#we can use gsub again
gsub(".", "_", dat_melted$Genus_sp) #¿? . has a special meaning!
dat_melted$Genus_sp <- gsub(".", "_", fixed = TRUE, dat_melted$Genus_sp)
#and I want to split Genus and species
#Lets use regexp full power
?regex
unique(dat_melted$Genus_sp)
m <- regexpr(pattern="^[A-Z][a-z]*([0-9])", dat_melted$Genus_sp, perl= TRUE) 
[0-9]
dat_melted$Genus <- regmatches(dat_melted$Genus_sp, m)
example <- c("1+1","2+3", "0+1")
m <- regexpr(pattern="^[0-9]+", example, perl= TRUE) 
first_column <- regmatches(example, m)

m <- regexpr(pattern="[a-z]*[0-9]+$", dat_melted$Genus_sp, perl= TRUE) 
dat_melted$species <- regmatches(dat_melted$Genus_sp, m)
str(dat_melted)

#database stile ----
#avoid redundant information by structuring data into tables

#Table of sites; 
unique(dat$Site)
sites <- data.frame(Site = c("A","B","C"), Land_use = c("agricultural", "forest", "mix"))
head(dat_melted)
#now I can merge both when needed
merge_variable <- paste(dat_melted$Site, dat_melted$Treatment)
dat_melted2 <- merge(dat_melted, sites, by = "Site", all = TRUE)
str(dat_melted)
str(dat_melted2)
head(dat_melted2)

#export it
write.csv(dat_melted, "example/clean_data.csv")

#Why this format? easy to work with-----
#e.g. go back to original format
cast(data = dat_melted, Site + Treatment + Date + CoVariate ~ Genus_sp, value = "counts", fun = sum)
#or pool only by site
cast(dat_melted, Site + Treatment ~ Genus_sp, value = "counts", fun = sum, na.rm = TRUE)
#or mean per sites
cast(dat_melted, Site ~ Genus_sp, value = "counts", fun = mean, na.rm = TRUE)

#summarize it (library dplyr)-----
#mean of the covariate by treatment, but only for date one?
dat_melted %.%
    group_by(Treatment) %.%
    filter(Date != "2014-03-01") %.%
    summarise(mean(CoVariate, na.rm = TRUE))
    
#make z-scores by site and store new data
new_data <- dat_melted %.%
                 group_by(Site, Treatment) %.%
                 mutate(z_counts = scale(counts))
#arrange
