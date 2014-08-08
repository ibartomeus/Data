#This code is adapted from Zuur et al. and borrows heavely from several sources
#Compiled by Vesna Gagic


#Load the data
#Use setwd() comand to set working directory 
Sparrows <- read.table(file = "example/SparrowsElphick.txt", header = TRUE)
#or find your data in your files
Sparrows <- read.table(file.choose(), header = TRUE)
names(Sparrows)
str(Sparrows)


######Outliers and influental points
summary(Sparrows)
summary(Sparrows$wingcrd)
hist(Sparrows$wingcrd)

boxplot(Sparrows$wingcrd,  ylab = "Wing length (mm)")
boxplot.stats(Sparrows$wingcrd)

dotchart(Sparrows$wingcrd, xlab = "Wing length (mm)",ylab = "Order of the data")

library(lattice)
Z <- cbind(Sparrows$wingcrd, Sparrows$tarsus,  Sparrows$head,
           Sparrows$culmen,  Sparrows$nalospi, Sparrows$wt)

colnames(Z) <- c("wing length", "tarsus length", "head length",
                 "culmen length", "nalospi to bill tip", "weight")

dotplot(as.matrix(Z), groups = FALSE,
        strip = strip.custom(bg = 'white',
        par.strip.text = list(cex = 0.8)),
        scales = list(x = list(relation = "free"),
                      y = list(relation = "free"),
                      draw = FALSE),
        col = 1, cex  = 0.5, pch = 16,
        xlab = "Value of the variable",
        ylab = "Order of the data from text file")

#How to remove it?

plot(Sparrows$wingcrd)
identify(Sparrows$wingcrd)#536
Sparrows2<-Sparrows[-536,]#exclude row 536
plot(Sparrows2$wingcrd)

boxplot.stats(Sparrows$wingcrd)
Sparrows2<-subset(Sparrows,wingcrd<63.5)#Use only values smaller than 63.5
plot(Sparrows2$wingcrd)

#In linear regression

#install.packages("car")
library(car)

Model1<- lm(wingcrd~head, data=Sparrows) 
plot(Sparrows$wingcrd,Sparrows$head)
identify(Sparrows$wingcrd,Sparrows$head)

plot(Model1, which = c(4))#concerned if >1
plot(Model1, which = c(5))
plot(Model1)


# Assessing Outliers
outlierTest(Model1) # Bonferonni p-value for most extreme obs

lm.influence(lm(Sparrows$wingcrd~Sparrows$head))
#This produces four components: $hat (high values=high leverage)
#$coefficients (change in the estimated coefficients which results when the ith case is dropped from the regression)
#$sigma (estimate of the residual standard error obtained when the ith case is dropped from the regression)
#$wt.res (weighted residuals or raw residuals if weights are not set 

#########################Homogeneity of variance

Biodiv <- read.table(file = "example/Biodiversity.txt", header = TRUE)
#Biodiv <- read.table(file.choose(),h=T)
Biodiv$fTreatment <- factor(Biodiv$Treatment) 
Biodiv$fNutrient <- factor(Biodiv$Nutrient) 
boxplot(Concentration ~ fTreatment * fNutrient, data = Biodiv)
bwplot(Concentration ~ fTreatment|fNutrient, data = Biodiv) 
 
M0 <- lm(Concentration ~ Biomass * fTreatment * fNutrient, data = Biodiv) 
plot(M0, which = c(1), add.smooth = FALSE)

###Possible soulution 1: Transformation 

M1 <- lm(log(Concentration+1) ~ Biomass * fTreatment * fNutrient, data = Biodiv) 
plot(M1, which = c(1), add.smooth = FALSE)

###Possible soulution 2: add variace function (better)
library(nlme) 
f1 <- formula(Concentration ~ Biomass * fTreatment * fNutrient) 
M0 <- gls(f1, data = Biodiv) 
M1A <-gls(f1, data = Biodiv, weights = varIdent( form =~ 1 | fTreatment * fNutrient)) 
M1B <-gls(f1, data = Biodiv, weights = varIdent(form =~1 | fNutrient)) 
M1C <-gls(f1, data = Biodiv, weights = varIdent(form =~1 | fTreatment)) 
summary(M1C)
anova(M0, M1A, M1B, M1C)
plot(M1A, which = c(1), add.smooth = FALSE)

#see all different variance classes
?varClasses

###############################Are the data normally distributed?

Sparrows$fMonth<-factor(Sparrows$Month,
                        levels = c(5, 6, 7, 8, 9, 10),
                        labels = c("May", "June", "July", "August",
                                   "Sept.", "Oct."))


Sparrows$I1 <- Sparrows$fMonth =="June" |
               Sparrows$fMonth =="July" |
               Sparrows$fMonth =="August"


hist(Sparrows$wt[Sparrows$I1],
     xlab = "Weight (g)", breaks = 30,
     main = "", ylab = "Frequency")



library(lattice)
histogram( ~ wt | fMonth, type = "count",
    xlab = "Weight (g)",
    ylab = "Frequency",
    nint=30,layout=c(1,3),
    strip.left = strip.custom(bg = 'white'),
    strip = F,
    col.line = "black", col = "white",
    scales = list(x = list(relation = "same"),
                  y = list(relation = "same"),
                  draw = TRUE),
    subset = fMonth =="June" | fMonth == "July" |fMonth == "August",
    data = Sparrows)

###Biodiversity data

M0 <- lm(Concentration ~ Biomass * fTreatment * fNutrient, data = Biodiv) 
plot(M0, which = c(2), add.smooth = FALSE)

M0 <- gls(Concentration ~ Biomass * fTreatment * fNutrient, data = Biodiv) 
qqnorm(resid(M0,type="n"))
qqline(resid(M0,type="n"))

###Possible soulution 1: Transformation 

M1 <- lm(log(Concentration+1) ~ Biomass * fTreatment * fNutrient, data = Biodiv) 
plot(M1, which = c(2), add.smooth = FALSE)

###Possible soulution 2: add variace function (better)
 
M1A <-gls(f1, data = Biodiv, weights = varIdent( form =~ 1 | fTreatment * fNutrient))  

qqnorm(resid(M1A,type="n"))
qqline(resid(M1A,type="n"))

shapiro.test(resid(M1A,type="n"))
shapiro.test(resid(M1))

########################Are there lots of zeros in the data?

hist(Biodiv$Concentration)

##########################Is there collinearity among the covariates?

M0 <- lm(Concentration ~ Biomass*Mesocosm  , data = Biodiv) 
vif(M0) # variance inflation factors

#Possible solution: center your data (see Holger Schielzeth 2010.Simple means to 
#improve the interpretability of regression coef?cients, Methods in Ecology and Evolution 1, 103?113)

M1 <- lm(Concentration ~ scale(Biomass, scale = F)*scale(Mesocosm, scale = F) , data = Biodiv) 
vif(M1) # variance inflation factors

##################What is relationship between Y and all Xs

pairs(Biodiv)

########################################Should we consider interactions?

#Take the data from species 1, Sex = 0 and Wing length >= 65
I1 <- Sparrows$SpeciesCode == 1 & Sparrows$Sex != "0" & Sparrows$wingcrd < 65
Wing1<- Sparrows$wingcrd[I1]
Wei1 <- Sparrows$wt[I1]
Mon1 <- factor(Sparrows$Month[I1])
Sex1<- factor(Sparrows$Sex[I1])


#Define Month and Sex as categorical variables
fMonth1 <- factor(Mon1,levels=c(5,6,7,8,9),
                labels=c("May","Jun","Jul","Aug","Sep"))
fSex1   <- factor(Sex1, levels=c(4,5),labels=c("Male","Female"))

M1 <- lm(Wei1 ~ Wing1*fMonth1*fSex1)
summary(M1)
anova(M1)

#Make the coplot
coplot(Wei1 ~ Wing1 | fMonth1 * fSex1, ylab = "Weight (g)",
       xlab = "Wing length (mm)",
       panel = function(x, y, ...) {
         tmp <- lm(y ~ x, na.action = na.omit)
         abline(tmp)
         points(x, y) })

################Are observations of the response variable independent?
str(Sparrows)

Model1<- lm(wingcrd~head*Year, data=Sparrows) 
durbinWatsonTest(Model1)

Model1<- gls(wingcrd~head*Year, data=Sparrows) 
acf(resid(Model1, type = "normalized"))
#be careful with NAs!This is because the gls function is removing the missing values,
# whereas the acf function assumes that the points are at the right time position.


library(sp)
data(meuse)
coordinates(meuse) = ~x+y
Vario1 <-variogram(log(zinc)~1, meuse)
plot(Vario1)
#Note that this variogram assumes isotropy; the strength of the spatial correlation is the same in each direction

#Another, commonly used tes it Moran's I (see spdep library)

#Possible solutions:
#Use random structure in lme or lmer
#Use correlation structure in gls: include an autocorrelation
#structure into the model. Then compare the models with and without an
#auto-correlation structure using theAIC,BIC, or if the models are nested, a likelihood ratio test
#For example, you can add: correlation = corCompSymm(form =~Year)for temoral correlations
#see all different correlation classes:
?corClasses 

#For using differen variance and correlation classes read: Zuur et al (2009). Mixed Effects Models
#and Extensions in Ecology with R. Springer
##############################################################
