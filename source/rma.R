#this scrip is written for command line execution for the html

method = 'justrma'
wd = "\./fileUpload/justrma_cde/"
outFile = "\./fileUpload/justrma_cde/cde_norm\.txt"
imageFile = "\./fileUpload/justrma_cde/cde_postBoxplot\.jpeg"

method = commandArgs()[4]
wd <- commandArgs()[5]
outFile <- commandArgs()[6]
imageFile <- commandArgs()[7]

print(method)
print(wd)
print(outFile)
print(imageFile)

orgwd = getwd()
setwd(wd)
eset = c()
if (method == 'gcrma') {
        print ('gcrma')
        library(gcrma)
        Data <- ReadAffy() ##read data in working directory
        eset <- gcrma(Data)
}

if (method == 'justrma') {
        print ('justrma')
        library(affy)
        eset <- justRMA()
}

setwd(orgwd)
##################################################
library(RColorBrewer)
colors <- brewer.pal(12, "Set3")
bitmap(imageFile, res = 72*4, pointsize = 12, type= "jpeg", height = 4, width = 4)
boxplot(as.data.frame(exprs(eset)), col = colors, main=paste(method, "boxplots", sep=' '), xaxt = "n", ylab="Log (base 2) intensities", cex.main = 1.4, cey.lab = 1.0)
names <- sub("CEL$", "", sampleNames(eset), perl =TRUE)
axis(1, las=2, at=c(1:length(names)), labels=names, cex.axis = 0.5)
dev.off()
##################################################
exprs2excel(eset, file=outFile )
