#~/PROGRAMS/R/bin/R --vanilla < preprocess.R --args "\./" rna resids rle nuse maplot boxplot hist 
#args = c("R", "vanilla", "prep", "rna", "resids", "rle", "nuse", "maplot", "boxplot", "hist");
#NOTE: the functions in this scriptuse global parameters due to memory considerations
library(RColorBrewer)
library(affy)
library(affyPLM)
##################################################
#find the optimum multipliers
getMultipliers<-function(sampleSize) {
	f <- floor(sqrt(sampleSize))
	c <- ceiling(sqrt(sampleSize))

	ff <- f
	cc <- c
	while(1) {
		if(ff*cc == sampleSize) break
		if(ff*cc > sampleSize) {ff = ff - 1; cc = c} 
		cc = cc + 1
	}

	mult <- new.env()
	mult$f <- ff
	mult$c <- cc
	return (as.list(mult))
}

##################################################
#form bitmapImage
bitmapResids<-function() {
	image(Pset, type="resids", cex.main = 0.7)
}
##################################################
bitmapBoxplot<-function() {
	boxplot(Data, col = colors, main="Boxplots Pre-Normalization", xaxt = "n", ylab="Log (base 2) intensities", cex.main = 1.4, cey.lab = 1.0)
	#axis(1, las=2, at=c(1:sampleSize), labels=sampleNames(Data), cex.axis = 0.5)
	axis(1, las=2, at=c(1:sampleSize), labels=names, cex.axis = 0.5)
}
##################################################
bitmapHistogram<-function() {
	hist(Data, ylim = c(0, 1.5), col = colors, lty = 1, main= "Histogram Pre-Normalization", xlab = "Log (base 2) intensities" )
	#legend(10, 1.5, sampleNames(Data), cex = 0.3, lty = 1, col = colors)
	legend(10, 1.5, names, cex = 0.3, lty = 1, col = colors)
}
##################################################
bitmapMAplot<-function() {
	MAplot(Data, cex = 0.6, cex.main = 0.4)
	mtext("M", 2, outer = TRUE)
	mtext("A", 1, outer = TRUE)
}
##################################################
bitmapRnaDegradation<-function() {
	#plotAffyRNAdeg(RNAdeg, col = colors, ylim = c(0, 80)) #ylim:multiple actual arguments
	plotAffyRNAdeg(RNAdeg, col = colors)
	#legend(-1, 60, RNAdeg$sample.names, cex = 0.3, lty = 1, col = colors)
	yaxisTop = 30;
	if (sampleSize > 10) { yaxisTop = 40 }
	if (sampleSize > 20) { yaxisTop = 50 }
	legend(-1, yaxisTop, names, cex = 0.3, lty = 1, col = colors)
}
##################################################
bitmapRLE<-function() {
	Mbox(Pset, ylim = c(-1, 1), col = colors, xaxt = "n", main = "Relative Log Expression")
	#axis(1, las=2, at=c(1:sampleSize), labels=sampleNames(Pset), cex.axis = 0.5)
	axis(1, las=2, at=c(1:sampleSize), labels=names, cex.axis = 0.5)
}
##################################################
bitmapNUSE<-function() {
	boxplot(Pset, ylim = c(0.9, 1.6), col = colors, xaxt = "n", names = NULL, main = "Normalized Unscaled Standard Error")
	#axis(1, las=2, at=c(1:sampleSize), labels=sampleNames(Pset), cex.axis = 0.5)
	axis(1, las=2, at=c(1:sampleSize), labels=names, cex.axis = 0.5)
}
##################################################
formOutfile<-function(dir, file) {
        return (paste(dir, file, "\.jpeg", sep = ""))
}
###################
args = commandArgs();
#args = c("R", "<<", "prog", "\./", "cde", "resids")
print(args)
###################
dir = args[4]
print (dir)
###################
orgwd = getwd()
setwd(dir)
Data <- ReadAffy() ##read data in working directory
names <- sub("CEL$", "", sampleNames(Data), perl =TRUE)
sampleNames(Data) <- names
setwd(orgwd)
###################
sampleSize = length(Data[[1]])
mult = getMultipliers(sampleSize);
rows = mult$f
cols = mult$c
###################
Pset <- c()
RNAdeg <- c()
for (i in 1:length(args)) {
	file = args[i]
	if (file=="resids" || file=="rle" || file=="nuse") {
		Pset <- fitPLM(Data); break
	}
	if (file=="rna") {
		RNAdeg <- AffyRNAdeg(Data); break
	}
}
###################
for (i in 5:length(args)) {
	file = args[i]

	outFile = formOutfile(dir, file)
	print(outFile)

	colors = c()
	if (file=="resids" || file=="maplot") {
		hei = rows * 2.0
		wid = cols * 1.5
		if (rows < 3 && cols < 3) {
			hei = 3
			wid = 3
		}
		bitmap(outFile, res = 72*4, pointsize = 12, type= "jpeg", height = hei, width = wid)
		par(mfrow = c(rows, cols) )
	} else { 
		colors <- brewer.pal(12, "Set3")
		bitmap(outFile, res = 72*4, pointsize = 12, type= "jpeg", height = 4, width = 4) 
	}

	if (file == "rna")	{ bitmapRnaDegradation() }
	if (file == "boxplot") 	{ bitmapBoxplot() }
	if (file == "hist") 	{ bitmapHistogram() }
	if (file == "maplot") 	{ bitmapMAplot() }
	if (file == "resids") 	{ bitmapResids() }
	if (file == "rle") 	{ bitmapRLE() }
	if (file == "nuse") 	{ bitmapNUSE() }

	dev.off()
}

###################
##################################################
