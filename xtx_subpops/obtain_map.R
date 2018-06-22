args = commandArgs(trailingOnly=TRUE)

infile = args[1];
outfile = args[2];
mapfile = args[3]

XtX_1 = read.table(file=infile,header=T,sep="\t")
histx.data = hist(XtX_1$XtX,xlab="bayenv2 XtX values",ylab="log10(frequency)",main="")
mapdata = read.table(file=mapfile,header=T)

# produce histogram
png(file=paste(outfile,".hist.png", sep=""))
plot(histx.data,main=paste(infile,sep=""))
dev.off()

# print XtXs
XtXs = merge( XtX_1, mapdata, by="SNPidentifier")
position=colnames(XtXs)[[4]]
sortedXtXs = XtXs[with(XtXs, order(chr, XtXs[,position], decreasing = F)),]
write.table(sortedXtXs,file=outfile,sep="\t",row.names=F,col.names=T,quote=F)

## END
