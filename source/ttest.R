library(affy)
library(annaffy)
library(hgu133plus2)
library(siggenes)
library(multtest)
library(genefilter)

##################################################
#this function extracts the ttest pair data from the whole expression set;
formCompDataClass<-function(normFile, grp1, grp2, dataS, dataCompS, classLabelS) {
        data <- read.csv(normFile)
	assign(dataS, data, env = .GlobalEnv)
        #attributes(data) #usefull command
        header = c(names(data))
	
	#match pattern and column header
	pat1 = findPattern(grp1)
	i1 <- (grep (pat1, header)) #indices that match pattern one in the header
        d1<-data[,i1] #extract indicated indice columns 

	pat2 = findPattern(grp2)
	i2 <- (grep (pat2, header))
        d2<-data[,i2]
       
	#form data frame 
        dataComp <- cbind(d1,d2)
	assign(dataCompS, dataComp, env = .GlobalEnv)

	#form t-test class labels
	classLabel = c()
	if (grp1 < grp2) { #first comes the smaller id labels -here grp1 as 0
		for (i in 1:length(i1)) { classLabel = c(classLabel, 0) }
		for (i in 1:length(i2)) { classLabel = c(classLabel, 1) }
	}
	else { #first comes the smaller id labels -here grp2 as 1
		for (i in 1:length(i2)) { classLabel = c(classLabel, 1) }
		for (i in 1:length(i1)) { classLabel = c(classLabel, 0) }
	}
	assign(classLabelS, classLabel, env = .GlobalEnv)
}

findPattern<-function(grp) {
	return (paste("X", grp, "_", sep = ""))
}
##################################################
#filter genes below explimit
filterExp<-function(explimit, dataComp, whichS) { 
	#27th Nov at least 1 probe should be expressed above explimit
	f1 <- kOverA(1, explimit)
	ffun <- filterfun(f1)
	which <- genefilter(dataComp, ffun)
	assign(whichS, which, env = .GlobalEnv)
	
}

##################################################

#to get regulation information
getRegulation<-function(dataCompFiltered, dataCompClassLabel, regulationS) {

	tmp <- mt.teststat.num.denum(dataCompFiltered, dataCompClassLabel, test = "t")
	num <- data.matrix(tmp$teststat.num)
	assign(regulationS, num, env = .GlobalEnv)
}

##################################################
#get raw p values of the ttest analysis type
getRawp<-function(dataCompFiltered, dataCompClassLabel, ttType, ttTail, ttVar, rawpS) {
	#find raw p values
#TODO incorporate paired ttest later
#TODO incorporate one-tailed ttest later
	var;
	if (ttVar == 'equal') var = T
	if (ttVar == 'unequal') var = F
	
	rft <- rowFtests(data.matrix(dataCompFiltered), factor(dataCompClassLabel), var.equal= var)
	rawp <- rft$p.value 
	assign(rawpS, rawp, env = .GlobalEnv)
}

##################################################
#get adjp values of the ttest analysis type
getAdjp<-function(rawp, procs, adjpS) {
	#adj_p is in its orijinal order -not in accending order
	res <- mt.rawp2adjp(rawp, procs)
	adjp <- res$adjp[order(res$index), ]
	assign(adjpS, adjp, env = .GlobalEnv)
}

##################################################
#write raw and adjusted p-value rejected hypothesis counts into file
formPvalueFile<-function(adjp, pvalueFile) {
	rejectedNumbers <- mt.reject(cbind(adjp), seq(0,1.0,0.01) )$r
        write.table(rejectedNumbers, file = pvalueFile, sep = "\t", col.names = TRUE, quote = FALSE)
}

##################################################
#write hgu133plus2 annotation fields from probe based rda files
formAnnotationData<-function(dataCompFilteredGnames, annotationMatrixS) {

	#The order is important
        title = c('SYMBOL', 'ACCNUM', 'CHRLOC', 'CHR', 'ENTREZID', 'ENZYME', 'GENENAME', 'GO', 'MAP', 'OMIM', 'PATH', 'PMID', 'REFSEQ', 'UNIGENE')

	matrix <- matrix("na",length(dataCompFilteredGnames), length(title))
	colnames(matrix) <- title

	for (i in 1:length(dataCompFilteredGnames)) {
	        id = dataCompFilteredGnames[i]
        	data = c()

	        data = c(data, paste(mget(id,env=hgu133plus2SYMBOL)[[1]], sep='', collapse=' /// '))
        	data = c(data, paste(mget(id,env=hgu133plus2ACCNUM)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2CHRLOC)[[1]], sep='', collapse=' /// '))
        	data = c(data, paste(mget(id,env=hgu133plus2CHR)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2ENTREZID)[[1]], sep='', collapse=' /// '))

	        data = c(data, paste(mget(id,env=hgu133plus2ENZYME)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2GENENAME)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2GO)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2MAP)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2OMIM)[[1]], sep='', collapse=' /// '))

	        data = c(data, paste(mget(id,env=hgu133plus2PATH)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2PMID)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2REFSEQ)[[1]], sep='', collapse=' /// '))
	        data = c(data, paste(mget(id,env=hgu133plus2UNIGENE)[[1]], sep='', collapse=' /// '))

	        matrix[i,] <- data.matrix(data)
	}
	assign(annotationMatrixS, matrix, env = .GlobalEnv)
}

##################################################
##################################################
#START OF THE PROGRAM
##################################################

ttType <- "unpaired"
ttTail <- "twotailed"
ttVar <- "unequal"
expLimit <- "3.0"
grp1 = "2N"
grp2 = "2P"
normFile = "\./justrma\.csv"
pvalueFile = "\./manual_pvalue\.txt"
sqlFile = "\./manual_sql.txt"
procs <- c("BH")
FDR <- 1.0

##################################################
#get command line arguments
ttType <- commandArgs()[4]
ttTail <- commandArgs()[5]
ttVar <- commandArgs()[6]
expLimit <- commandArgs()[7]
grp1 = commandArgs()[8]
grp2 = commandArgs()[9]
normFile = commandArgs()[10]
pvalueFile = commandArgs()[11]
sqlFile = commandArgs()[12]
procs = c()
for (i in 13:length(commandArgs())) {
	procs <- c(procs, commandArgs()[i])
}
FDR <- 1.0

print (commandArgs())

##################################################
#IMPORTANT nmeric comparison
expLimit = as.numeric(expLimit)
##################################################
#read data and assign data dataComp dataCompClassLabel

data = c()
dataComp = c()
dataCompClassLabel = c()
formCompDataClass(normFile, grp1, grp2, "data", "dataComp", "dataCompClassLabel") 
#assign dataCompGnames
dataCompGnames = data.matrix(data[,1])

print(dim(data))
print(dim(dataComp))
print(length(dataCompGnames))
##################################################
#filter according to explimit
which = c()

filterExp(expLimit, dataComp, "which") 

dataCompFiltered <- dataComp[which,]
dataFiltered <- data[which,]
dataCompFilteredGnames <- dataCompGnames[which,1]

print(dim(dataFiltered))
print(dim(dataCompFiltered))
print(length(dataCompFilteredGnames))

##################################################
#get rawp

rawp = c()
getRawp(dataCompFiltered, dataCompClassLabel, ttType, ttTail, ttVar, "rawp")
print (dim(data.matrix(rawp)))

#IMPORTANT
#drop NA values
which <- !is.na(rawp)

rawp   <- rawp[which, drop=FALSE]
dataCompFiltered <- dataCompFiltered[which, ,drop=FALSE]
dataFiltered <- dataFiltered[which, ,drop=FALSE]
dataCompFilteredGnames <- dataCompFilteredGnames[which, drop=FALSE]

print (dim(data.matrix(rawp)))
print (dim(data.matrix(dataCompFiltered)))
print (dim(data.matrix(dataCompFilteredGnames)))

##################################################
#get adjp

adjp = c()
getAdjp(rawp, procs, "adjp")
print (dim(data.matrix(adjp)))
print ((data.matrix(adjp))[1:10,])

##################################################
#write raw and adjusted p-value rejected hypothesis counts into file
formPvalueFile(adjp, pvalueFile)

print("formPvalueFile finished")
##################################################
#get regulation: down or up
dataCompFilteredRegulation = c()

getRegulation(dataCompFiltered, dataCompClassLabel, "dataCompFilteredRegulation")

print ("dataCompFilteredRegulation")
print (dim(dataCompFilteredRegulation))
print (dataCompFilteredRegulation[1:10,])	

##################################################
#get hgu133plus2 annotation fields from probe based rda files
annotationMatrix = c()
formAnnotationData(dataCompFilteredGnames, "annotationMatrix")
print("formAnnotationData finished")
##################################################
#write sql file 
write.table(cbind(dataCompFilteredGnames, dataCompFilteredRegulation, annotationMatrix, adjp, dataFiltered[,-1]), file = sqlFile, sep = "\t", col.names = TRUE, row.names = FALSE, quote = FALSE)	
print("formSqlFile finished")
##################################################
