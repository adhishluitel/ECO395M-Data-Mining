library(tidyverse)
library(LICORS)
library(ISLR)
library(foreach)
library(mosaic)
library(GGally)
library(corrplot)
library(ggplot2)
library(DescTools)

wine_data <- "https://raw.githubusercontent.com/jgscott/ECO395M/master/data/wine.csv"
wine <- read.csv(url(wine_data))
head(wine)

# Center and scale the data, data visualization
z = wine[,1:11]
z = scale(z, center=TRUE, scale=TRUE)
z_std = scale(z)
mu = attr(z_std,"scaled:center")
sigma = attr(z_std,"scaled:scale")
res <- cor(z_std)
corrplot(res, type = 'lower', method = "color", order = "hclust", hclust.method = "ward.D", tl.cex = 0.5, tl.col="black")
#corrplot(res, method = "color", tl.cex = 0.5, tl.col="black") - full corrplot, it was symmetric so I removed it




#Clustering
#Start with K means 2 as we have two basic categories (Red/White) and 25 starts
cluster1 = kmeans(z_std, 2, nstart=25) 

#Picking variables
sort(cluster1$centers[1,], decreasing=TRUE)
sort(cluster1$centers[2,], decreasing=TRUE)

#Comparing 
Cluster = factor(cluster1$cluster)
#total.sulfur.dioxide, free.sulfur.dioxide and residual.sugar have the highest coefficients


subset(wine, select = c("total.sulfur.dioxide","free.sulfur.dioxide","residual.sugar")) %>%
  ggpairs(legend = 1, aes(color=Cluster, alpha = 0.6),
          upper = list(integer = wrap("cor", size=2, alignPercent=0.8))) +
  theme_bw() + theme(legend.position = "bottom", panel.grid = element_blank())
###

wine$cluster = cluster1$cluster
wine = wine %>%
  group_by(cluster) %>%
  mutate(color_hat = Mode(color))

#Confusion matrix
table1 = xtabs(~wine$color_hat + wine$color) ###
print(table1)
#Accuracy 6405/6497 = 98.58%

# Using kmeans++ clustering
cluster_kpp = kmeanspp(z_std, k=2, nstart=25)
qplot(fixed.acidity, chlorides, data=wine, color=factor(cluster_kpp$cluster))#remove

wine$cluster_kpp = cluster_kpp$cluster
wine = wine %>%
  group_by(cluster_kpp) %>%
  mutate(color_hat_kpp = Mode(color))
#Confusion matrix
table2 = xtabs(~wine$color_hat_kpp + wine$color) ###
print(table2)
#Same as Kmeans clustering. No improvement


#Now, PCA
pca = prcomp(z_std, scale=TRUE)
summary(pca) #note the proportion of variance. PC1-PC3 look pretty significant. 
#Combined they form 0.6436/1 = 64.3% of the total variance in the dataset

scores = pca$x
loadings = pca$rotation

# PCA for clustering
cluster_pca = kmeans(scores[,1:3], 2, nstart=25) # Ran k-means with 2 clusters and 25 starts
qplot(scores[,1], scores[,2], data=wine, color=factor(cluster_pca$cluster))

# PCA confusion matrix table
table3 = xtabs(~cluster_pca$cluster + wine$color) 
print(table3)
#accuracy rate K-means=2 is 6391/6497 = 98.3%. Pretty accurate but slightly worse than clustering


#But does this technique also seem capable of sorting the higher from the lower quality wines?
#Now we have to distinguish the quality of wine. Scale of 1-10, so we have 10 categories
#So we will try to cluster into 10 categories
# kmeans clustering
z = scale(z, center=TRUE, scale=TRUE)
z_std = scale(z)
z_std = z

cluster2 = kmeans(z_std, 7, nstart=25)
wine$cluster2 = cluster2$cluster
table_wine = wine %>%
  group_by(cluster2) %>%
  summarize(quality_3 = sum(quality == 3),
            quality_4 = sum(quality == 4),
            quality_5 = sum(quality == 5),
            quality_6 = sum(quality == 6),
            quality_7 = sum(quality == 7),
            quality_8 = sum(quality == 8),
            quality_9 = sum(quality == 9))
print(table_wine)


Clusterq = factor(cluster2$cluster)

subset(wine, select = c("fixed.acidity","total.sulfur.dioxide","alcohol","sulphates")) %>%
  ggpairs(legend = 1, aes(color=Clusterq, alpha = 0.6),
          upper = list(integer = wrap("cor", size=2, alignPercent=0.8))) +
  theme_bw() + theme(legend.position = "bottom", panel.grid = element_blank())

#Confusion martix
table4 = xtabs(~cluster2$cluster + wine$quality)
print(table4)

#Density plots
ggplot(wine)+ geom_density(aes(x = cluster2$cluster, col = factor(wine$quality), fill = factor(wine$quality)), alpha = 0.4)
ggplot(wine)+ geom_density(aes(x = wine$quality, col = factor(wine$quality), fill = factor(wine$quality)), alpha = 0.4)

# kmeans++ clustering
cluster_kpp2 = kmeanspp(z_std, 7, nstart=25)

#Confusion martix
table4 = xtabs(~cluster_kpp2$cluster + wine$quality)
print(table4)

# Now PCA
pca2 = prcomp(z_std, scale=TRUE)
summary(pca2)
loadings = pca2$rotation
scores = pca2$x
# PCA for clustering
cluster_pca1 = kmeans(scores[,1:3], 7, nstart=25)
qplot(scores[,1], scores[,2], data=wine, color=factor(cluster_pca1$cluster), xlab='Component 1', ylab='Component 2')
summary(cluster_pca1$centers)
#Confusion matrix for PCA
table5 = xtabs(~cluster_pca1$cluster + wine$quality)
print(table5)
ggplot(wine)+ geom_density(aes(x = cluster_pca1$cluster, col = factor(wine$quality), fill = factor(wine$quality)), alpha = 0.5)

#Very hard differentiate quality of wine from chemical features 

