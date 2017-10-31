library("affy")
library("ALLMLL")
data(MLL.B)
Data <- MLL.B[, c(2, 1, 3:5, 14, 6, 13)]
sampleNames(Data) <- letters[1:8]

bitmap("image.jpeg", res = 72*4, pointsize = 12, type= "jpeg")
#log transformation
image(Data[, 1])
dev.off()

bitmap("boxplot.jpeg", res = 72*4, pointsize = 12, type= "jpeg")
cols <- brewer.pal(8, "Set1")[-6]
boxplot(Data, col = cols)
dev.off()

bitmap("hist.jpeg", res = 72*4, pointsize = 12, type= "jpeg")
hist(Data, col = cols, lty = 1, xlab = "Log (base 2) intensities")
legend(12, 1, letters[1:8], lty = 1, col = cols)
dev.off()

bitmap("ma.jpeg", res = 72*4, pointsize = 12, type= "jpeg",  height = 10, width = 10)
par(mfrow = c(2, 4))
MAplot(Data, cex = 0.75)
mtext("M", 2, outer = TRUE)
mtext("A", 1, outer = TRUE)
dev.off()


library("AmpAffyExample")
data(AmpData)
sampleNames(AmpData) <- c("N1", "N2", "N3", "A1", "A2", "A3")
RNAdeg <- AffyRNAdeg(AmpData)
bitmap("rnaDeg.jpeg", res = 72*4, pointsize = 12, type= "jpeg",  height = 10, width = 10)
plotAffyRNAdeg(RNAdeg, col = c(2, 2, 2, 3, 3, 3))
dev.off()
#boxplots

library("affyPLM")
Pset1 <- fitPLM(AmpData)
show(Pset1)


par(mfrow = c(2, 2))
bitmap("ampdata.jpeg", res = 72*4, pointsize = 12, type= "jpeg",  height = 10, width = 10)
image(AmpData[, 3])
dev.off()

bitmap("weights.jpeg", res = 72*4, pointsize = 12, type= "jpeg",  height = 10, width = 10)
image(Pset1, type = "weights", which = 3)
dev.off()

bitmap("resids.jpeg", res = 72*4, pointsize = 12, type= "jpeg",  height = 10, width = 10)
image(Pset1, type = "resids", which = 3)
dev.off()

bitmap("signResids.jpeg", res = 72*4, pointsize = 12, type= "jpeg",  height = 10, width = 10)
image(Pset1, type = "sign.resids", which = 3)
dev.off()

bitmap("mbox.jpeg", res = 72*4, pointsize = 12, type= "jpeg",  height = 10, width = 10)
Pset2 <- fitPLM(MLL.B)
Mbox(Pset2, ylim = c(-1, 1), col = cols, names = NULL, main = "RLE")
dev.off()


