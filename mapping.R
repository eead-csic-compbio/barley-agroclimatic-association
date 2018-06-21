library(ggplot2)

# mapping function
snpmap <- function(snp=NULL, snpname=NULL, clim=NULL, climname=NULL,
                   border=NULL, size=1, scale=FALSE) {
  
  if (is.null(snp) & is.null(clim)) stop('at least one of (snp, clim) need to be specified')
  #if (!is.null(snp) & is.null(snpname)) stop('snpname needs to be specified if snp table is provided')
  if (!is.null(clim) & is.null(climname)) stop('climname needs to be specified if clim table is provided')
  
  # climatology (raster)
  if (!is.null(climname)) {
    w <- which(names(clim)==climname)
    if(length(w)==0) stop(paste('There is no variable',climname))
    clim <- as.data.frame(rasterToPoints(raster(clim, layer=w)))
    #clim <- clim[,c(1,2,which(colnames(clim)==climname))]
    colnames(clim) <- c('utmx', 'utmy', 'val')
    if (scale) {
      clim$val <- scale(clim$val, center=TRUE, scale=TRUE)
    }
  }

  if (!is.null(snpname)) {
    symbol <- factor(snp[,snpname], levels=c('A','C','G','T','missing','-'))
  }
  if (is.null(snpname) & !is.null(snp)) {
    symbol <- rep('snp', nrow(snp))
    snpname <- 'sample'
  }
  
  g <- ggplot() + coord_equal() + theme_bw() +
    #ggtitle(paste(snpname, climname)) +
    theme(axis.title.x=element_blank(), axis.title.y=element_blank(),
          axis.text.y=element_text(angle=90, hjust=0.5))
  if (!is.null(climname)) {
    g <- g +
      geom_tile(data=clim, aes(utmx, utmy, fill=val)) +
      scale_fill_gradientn(colors=terrain.colors(10), name=climname)
  }
  if (!is.null(border)) {
    g <- g + 
      geom_polygon(data=esp, aes(x=long, y=lat), col='black',
                   fill=NA, alpha=0.75)
  }
  # symbology according to SNP name
  if (!is.null(snpname)) {
    g <- g +
      geom_point(data=snp, aes(utmx, utmy, shape=symbol), size=size) +
      geom_point(data=snp, aes(utmx, utmy, color=symbol, shape=symbol),
                 size=size*0.7) +
      scale_color_manual(
        breaks=c('A','C','G','T','missing','-'),
        values=c('#e7298a','#1b9e77','#7570b3','#d95f02','black','black')) +
      scale_shape_manual(
        breaks=c('A','C','G','T','missing','-'),
        values=c(16,15,17,18,3,3)) + # c(21,22,23,24,3,3)
  #      labs(x=NULL, y=NULL, color=snpname, shape=snpname)
      labs(color=snpname, shape=snpname)
  }
  return(g)
}

snpreg <- function(snp, snpname, clim, climname, climlabel=NULL) {
  # based on http://stackoverflow.com/questions/35366499/ggplot2-how-to-combine-histogram-rug-plot-and-logistic-regression-prediction
  library(dplyr)

  # Prepare data
  y <- snp
  coordinates(y) <- snp[,c(2,3)]
  x1 <- extract(clim, y)[,climname]
  y <- y[,snpname]@data[,1]
  dat <- data.frame(y=y, x1=x1)
  dat <- dat[complete.cases(dat),]
  dat <- dat[dat$y!='-',]
  dat$y <- factor(dat$y)
  
  # to control X-axis label if desired
  if(is.null(climlabel)) { climlabel <- climname }
  
  # select the most frequent alele and use it as the reference
  reflevel <- names(sort(table(dat$y), decreasing=TRUE))[1]
  dat$y1 <- as.numeric(dat$y==reflevel)
  
  # Binomial GLM
  xreg <- seq(0.9*min(dat$x1),1.1*max(dat$x1),length.out=100)
  yreg <- predict(glm(y1~x1, family='binomial', data=dat),
                  newdata=data.frame(x1=xreg),type='response')

  # Summarise data to create histogram counts
  xreg2 <- seq(0.9*min(dat$x1),1.1*max(dat$x1),length.out=12)
  h <- dat[,-1] %>% group_by(y1) %>%
    mutate(breaks=cut(x1, breaks=xreg2, labels=xreg2[-1]-diff(xreg2)/2, 
                        include.lowest=TRUE),
           breaks=as.numeric(as.character(breaks))) %>%
    group_by(y1, breaks) %>% 
    summarise(n=n()) %>%
    mutate(pct=ifelse(y1==0, n/sum(n), 1-n/sum(n)))

  # Plot
  ggplot() +
    geom_segment(data=h, aes(x=breaks, xend=breaks, y=y1, yend=pct, color=factor(y1)),
                 size=8, show.legend=FALSE) +
    geom_segment(dat=dat[dat$y1==0,], aes(x=x1, xend=x1, y=0, yend=-0.02),
                 size=0.2, colour="grey10") +
    geom_segment(dat=dat[dat$y1==1,], aes(x=x1, xend=x1, y=1, yend=1.02),
                 size=0.2, colour="grey10") +
    geom_line(data=data.frame(x=xreg, y=yreg), 
              aes(x,y), colour="grey50", lwd=1) +
    xlab(climlabel) +
    ylab(reflevel) +
    ggtitle(snpname) +
    theme_bw()
  
}

# Multiple plot function
#
# ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
# - cols:   Number of columns in layout
# - layout: A matrix specifying the layout. If present, 'cols' is ignored.
#
# If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
# then plot 1 will go in the upper left, 2 will go in the upper right, and
# 3 will go all the way across the bottom.
#
multiplot <- function(..., plotlist=NULL, file, cols=1, layout=NULL) {
  library(grid)
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}
