# Internal function: Plot the time series comparison data generated by function compareTS.R
#
# The data object generated by function compareTS.R contains both time series properties and model parameters.
# Please use names(data) to list available slots.
# Examples for time series properties are: pink, brown, taylorslope, taylorr2, timedecayr2
# Examples for fitting properties are (function compareFit.R): slope, maxcorr, Acorr
# Examples for parameters are: interval, pep, sigma, theta
#
# Note: biplot is outcommented to avoid compilation errors in seqtime
#
# data: output of compareTS.R, optionally merged with output of compareFit.R
# distribs: only needed for type rankabund, output of compareTS with returnDistribs set to TRUE
# colorBy: a model parameter by which to color, determines the labels of the summary plot, not supported by pca or by rankabund with generator set to all, expId can be selected to color by experiment
# type: the plot to do (boxplot, summary, rankabund, biplot or pca), boxplot will plot a boxplot with the property values per generator and color dots according to colorBy (requires ggplot2), summary will summarize noise types for each experiment, rankabund will do rank-abundance plots, biplot will draw a biplot across the noise types, autocorrelation slope, Taylor R2, neutrality test p-value and LIMITS correlation (requires ggplot2 and ggbiplot) and pca will do a PCA plot across the 4 maximum autocorrelation bins
# property: a time series property (boxplot)
# custom.header: custom header, if empty, a default will be composed of data names (for boxplot and summary)
# summary.type: the type of the summary plot, either noise, hurst or autocor (summary)
# summary.legend: whether or not to display the legend of the summary plot
# nt.predef: when noise types were computed using predef (assuming smoothing is TRUE), all non-black,non-brown and non-pink taxa can be interpreted as white (so color is white and white is added in biplot), otherwise this assumption cannot be made (so color is grey and white is omitted from biplot)
# jitter.width: jitter control (boxplot)
# dot.size: dot size control (boxplot)
# sig: for p-values: display significance (boxplot)
# pcs: principal components (pca)
# useGgplot: use ggplot2 to create the summary plot (summary), requires ggplot2 and reshape2
# skipIntervals: only plot time series with interval 1, supported for box plot, pca and summary plot
# skipHighDeathrate: avoid hubbell time series with high death rate (> 100), supported for box plot, pca and summary plot
# skipGenerators: list of generators to skip, supported for box plot, pca and summary plot
# addInitAbund: add broken-stick-distributed initial abundances (rankabund)
# norm: normalize abundances (rankabund)
# taxonNum: the number of taxa to plot, if NA, all are plotted (rankabund)
# generator: generator for which rank-abundance curves should be plotted, defaults to all, options: glv, ricker, soi, dm, hubbell, davida, davidb, all
# pch: which point character to use for the plot (rankabund)
# maxautocorBins: the bins used for the maximal autocorrelation, needed to set labels correctly (boxplot)
# hurstBins: the bins used for the Hurst exponent, needed to set labels correctly (boxplot)
# no.xlabels: suppress x labels (summary)
# makeggplot: plot the ggplot2 object (only if ggplot2 plot was made)
#
# Returns: a ggplot2 object if ggplot2 plot was carried out
#
# Examples:
# plotObj=plotTSComparison(table,property="taylorslope", colorBy="pep", jitter.width = 0.01)
# plotTSComparison(table,type="summary",colorBy ="algorithm")
# plotTSComparison(table,distribs, type="rankabund", norm=TRUE, taxonNum=10)
# plotTSComparison(table,distribs, type="rankabund", generator="dm", colorBy="initabundmode", addInitAbund = TRUE,norm = TRUE, taxonNum=15)
#
# Note: ggbiplot is outcommented so as not to disturb the seqtime build (avoid ggbiplot package dependency)

plotTSComparison<-function(data, distribs, colorBy="interval", type="boxplot", property="pink", custom.header="", summary.type="noise", summary.legend=TRUE, nt.predef=FALSE, jitter.width=0.1, dot.size=3, sig=FALSE, pcs=c(1,2), useGgplot=FALSE, skipIntervals=FALSE, skipHighDeathrate=FALSE, skipGenerators=c(), addInitAbund=FALSE, norm=FALSE, taxonNum=NA, generator="all", pch="", maxautocorBins=c(0.3,0.5,0.8), hurstBins=c(0.5,0.7,0.9), no.xlabels=FALSE, makeggplot=TRUE){
  if(!is.data.frame(data)){
    data=as.data.frame(data)
  }
  if(type=="rankabund" && !is.data.frame(distribs)){
    distribs=as.data.frame(distribs)
  }
  ylim=c(NA,NA)
  ggplotObj=NULL
  data["expId"]=c(1:length(data$algorithm))
  # set negative sigma to zero
  data$sigma[data$sigma<0]=0
  # update SOC to SOI
  levels(data$algorithm)[levels(data$algorithm)=="soc"]="soi"
  descript=property
  colorByDescript=colorBy
  if(property=="pink"){
    descript="percentage of pink OTUs"
    ylim=c(0,100)
  }else if(property=="brown"){
    descript="percentage of brown OTUs"
    ylim=c(0,100)
  }else if(property=="black"){
    descript="percentage of black OTUs"
    ylim=c(0,100)
  }else if(property == "maxautocorbin4"){
    descript=paste("percentage of OTUs in maximum auto-correlation bin [",maxautocorBins[3],",1]",sep="")
  }else if(property == "maxautocorbin3"){
    ylim=c(0,100)
    descript=paste("percentage of OTUs in maximum auto-correlation bin [",maxautocorBins[2],",",maxautocorBins[3],")",sep="")
  }else if(property == "maxautocorbin2"){
    ylim=c(0,100)
    descript=paste("percentage of OTUs in maximum auto-correlation bin [",maxautocorBins[1],",",maxautocorBins[2],")",sep="")
  }else if(property == "maxautocorbin1"){
    ylim=c(0,100)
    descript=paste("percentage of OTUs in maximum auto-correlation bin [0,",maxautocorBins[1],"]",sep="")
  }else if(property=="lowhurst"){
    ylim=c(0,100)
    descript=paste("percentage of OTUs in Hurst exponent bin [0,",hurstBins[1],"]",sep="")
  }else if(property=="middlehurst"){
    ylim=c(0,100)
    descript=paste("percentage of OTUs in Hurst exponent bin [",hurstBins[1],",",hurstBins[2],")",sep="")
  }else if(property=="highhurst"){
    ylim=c(0,100)
    descript=paste("percentage of OTUs in Hurst exponent bin [",hurstBins[2],",",hurstBins[3],")",sep="")
  }else if(property=="veryhighhurst"){
    ylim=c(0,100)
    descript=paste("percentage of OTUs in Hurst exponent bin [",hurstBins[3],",1]",sep="")
  }else if(property=="varevolslope"){
    descript="slope of the variance over time"
  }else if(property=="varevolr2"){
    descript="R2 of variance over time"
    ylim=c(0,1)
  }else if(property == "Acorr"){
    ylim=c(0,1)
    descript="LIMITS interaction matrix correlation"
  }else if(property=="corrAll"){
    ylim=c(-0.1,1)
    # for all species considered for fit
    descript="LIMITS mean cross-correlation"
  }else if(property=="neutralfull" || property=="neutralslice" || property=="neutral"){
    descript="p-value"
    ylim=c(0,1)
  }else if(property=="acc"){
    descript="accuracy"
  }else if(property=="maxcorr"){
    # for the sub-set of species giving the maximum cross-correlation
    descript="maximum mean cross-correlation between predicted and observed time series"
  }else if(property=="taylorslope"){
    descript="slope of Taylor law"
  }else if(property=="taylorr2"){
    descript="R2 of Taylor law"
  }else if(property=="veryhighhurst"){
    descript="percentage of OTUs in Hurst property bin [0.9,1]"
  }else if(property=="deltaAest"){
    descript="range of inferred interaction strengths"
  }else if(property=="autoslope"){
    descript="slope of mean autocorrelation versus species number"
  }else if(property=="timedecayr2"){
    descript="R2 of log(dissimilarity) and log(deltaT)"
  }else if(property=="timedecayslope"){
    descript="slope of log(dissimilarity) and log(deltaT)"
  }else if(property=="initlast"){
    descript="difference between initial and final taxon proportions"
  }else if(property=="soir2"){
    descript="SOI fitting mean R2"
  }else if(property=="avgtimescale"){
    descript="average time scale in days"
    ylim=c(0,NA)
  }else if(property=="upperbound"){
    descript="upper bound for sampling period in days"
    ylim=c(0,NA)
  }

  if(colorBy=="pep"){
    colorByDescript="PEP"
  }else if(colorBy=="initabundmode"){
    colorByDescript="initial abundance distribution type"
  }else if(colorBy=="c"){
    colorByDescript="connectance"
  }

  if(skipIntervals==TRUE || skipHighDeathrate==TRUE || length(skipGenerators)>0){
    data=filterData(data, type=type, summary.type = summary.type, property = property, colorBy = colorBy, skipIntervals = skipIntervals, skipHighDeathrate = skipHighDeathrate, skipGenerators = skipGenerators)
  }

  # check whether ggplot2 is there
  if(type=="boxplot" || (type=="summary" && useGgplot==TRUE) || type=="biplot"){
    searchggplot=length(grep(paste("^package:","ggplot2", "$", sep=""), search()))
    if(searchggplot>0){
      ggplotPresent=TRUE
    }else{
      stop("Please install/load ggplot2 for this plot option.")
    }
  }

  # check whether ggbiplot is there
  if(type=="biplot"){
    searchggbiplot=length(grep(paste("^package:","ggbiplot", "$", sep=""), search()))
    if(searchggbiplot>0){
      ggbiplotPresent=TRUE
    }else{
      stop("Please install/load ggbiplot for this plot option.")
    }
  }

  if(type=="boxplot"){
    generatorDescr="Data set"
    if(custom.header!=""){
      title=custom.header
    }else{
      title=paste(generatorDescr," versus ",descript, " colored by ",colorByDescript,sep="")
    }
    if(is.na(ylim[1]) || is.na(ylim[2])){
      if(is.na(ylim[1])){
        ymin=min(data[property],na.rm=TRUE)
      }else{
        ymin=ylim[1]
      }
      if(is.na(ylim[2])){
        ymax=max(data[property],na.rm=TRUE)
      }else{
        ymax=ylim[2]
      }
      ylim=c(ymin,ymax)
    }
    #print(customizeGeneratorNames(as.character(data$algorithm)))
    data$algorithm=as.factor(customizeGeneratorNames(as.character(data$algorithm)))
    if(sig==TRUE){
      #print(data[property][[1]][1:5])
      # treat zeros
      zero.indices=which(data[property]==0)
      non.zero.indices=which(data[property]>0)
      min.pval=min(data[property][[1]][non.zero.indices])
      # pseudocount
      pseudocount=min.pval-(min.pval/2)
      print(paste("Pseudo-count:",pseudocount))
      data[property][[1]][zero.indices]=pseudocount
      # compute significance
      data[property]=-1*log10(data[property])
      print("Transforming p-values")
      ymin=min(data[property],na.rm=TRUE)
      ymax=max(data[property],na.rm=TRUE)
      ylim=c(ymin,ymax)
      descript="-log10(p-value)"
      y.intercept=1.3 # sig corresponding to p-value 0.05
      ggplotObj <- ggplot2::ggplot(data, ggplot2::aes(factor(algorithm),data[property])) + ggplot2::geom_boxplot() + ggplot2::geom_jitter(ggplot2::aes(colour=factor(unlist(data[colorBy]))), width=jitter.width, size=dot.size) + ggplot2::coord_cartesian(ylim=ylim) + ggplot2::geom_hline(yintercept = y.intercept, stat = 'hline', linetype="dotted") + ggplot2::ggtitle(title) + ggplot2::xlab("") + ggplot2::ylab(firstup(descript)) + ggplot2::theme(legend.title=ggplot2::element_blank(), axis.text.x = ggplot2::element_text(angle=90,size=11))
    }else{
      if(property=="avgtimescale" || property=="upperbound"){
        ggplotObj <- ggplot2::ggplot(data, ggplot2::aes(factor(algorithm),data[property])) + ggplot2::geom_hline(yintercept = 1, stat = 'hline', linetype="dotted") + ggplot2::geom_boxplot() + ggplot2::geom_jitter(ggplot2::aes(colour=factor(unlist(data[colorBy]))), width=jitter.width, size=dot.size) + ggplot2::coord_cartesian(ylim=ylim) + ggplot2::ggtitle(title) + ggplot2::xlab("") + ggplot2::ylab(firstup(descript)) + ggplot2::theme(legend.title=ggplot2::element_blank(), axis.text.x = ggplot2::element_text(angle=90,size=11))
      }else{
        ggplotObj <- ggplot2::ggplot(data, ggplot2::aes(factor(algorithm),data[property])) + ggplot2::geom_boxplot() + ggplot2::geom_jitter(ggplot2::aes(colour=factor(unlist(data[colorBy]))), width=jitter.width, size=dot.size) + ggplot2::coord_cartesian(ylim=ylim) + ggplot2::ggtitle(title) + ggplot2::xlab("") + ggplot2::ylab(firstup(descript)) + ggplot2::theme(legend.title=ggplot2::element_blank(), axis.text.x = ggplot2::element_text(angle=90,size=11))
      }
    }
    # remove legend title: theme(legend.title=element_blank())
  }else if(type=="summary"){
    # bar plot with OTU percentages in each category
    nrowComp=4
    if(nt.predef==FALSE){
      nrowComp=5
    }
    if(summary.type=="autocor" || summary.type=="hurst"){
      nrowComp=5
    }
    composition=matrix(NA,nrow=nrowComp, ncol=length(data$algorithm))
    labelcolors=c()
    for(i in 1:length(data$algorithm)){
      if(summary.type=="noise"){
        composition[1,i]=as.numeric(data$pink[i])
        composition[2,i]=as.numeric(data$brown[i])
        composition[3,i]=as.numeric(data$black[i])
        if(nt.predef){
          # there are no unclassified taxa, all remaining taxa are white
          composition[4,i]=100-sum(composition[1:3,i])
        }else{
          # white taxa
          composition[4,i]=as.numeric(data$white[i])
          # grey taxa
          composition[5,i]=100-sum(composition[1:4,i])
        }
      }else if(summary.type=="autocor"){
        composition[1,i]=as.numeric(data$maxautocorbin1[i])
        composition[2,i]=as.numeric(data$maxautocorbin2[i])
        composition[3,i]=as.numeric(data$maxautocorbin3[i])
        composition[4,i]=as.numeric(data$maxautocorbin4[i])
        composition[5,i]=100-sum(composition[1:4,i])
      }else if(summary.type=="hurst"){
        composition[1,i]=as.numeric(data$lowhurst[i])
        composition[2,i]=as.numeric(data$middlehurst[i])
        composition[3,i]=as.numeric(data$highhurst[i])
        composition[4,i]=as.numeric(data$veryhighhurst[i])
        composition[5,i]=100-sum(composition[1:4,i])
      }
      labelcolor="black"
      if(data$interval[i]==5){
        labelcolor="green"
      }else if(data$interval[i]==10){
        labelcolor="blue"
      }
      else if(!is.na(data$deaths[i]) && data$deaths[i]>100){
        labelcolor="red"
      }
      else if(!is.na(data$deaths[i]) && data$deaths[i]>50 && data$deaths[i]<500){
        labelcolor="deeppink"
      }
      else if(!is.na(data$sigma[i]) && data$sigma[i]==0.01){
        labelcolor="orange"
      }
      else if(!is.na(data$sigma[i]) && data$sigma[i]==0.05){
        labelcolor="darkgoldenrod"
      }
      else if(!is.na(data$sigma[i]) && data$sigma[i]==0.1){
        labelcolor="brown"
      }
      labelcolors=c(labelcolors,labelcolor)
    }
    # re-arrange according to algorithm
    ricker=which(data$algorithm=="ricker")
    glv=which(data$algorithm=="glv")
    hubbell=which(data$algorithm=="hubbell")
    dm=which(data$algorithm=="dm")
    davida=which(data$algorithm=="davida")
    davidb=which(data$algorithm=="davidb")
    soi=which(data$algorithm=="soi")
    indices=c(ricker,glv,hubbell,dm,davida,davidb,soi)
    # assign names according to colorBy property
    names=c()
    for(reorderedIndex in indices){
      names=c(names,as.character(data[[colorBy]][reorderedIndex]))
    }
    composition=composition[,indices]
    labelcolors=labelcolors[indices]
    colnames(composition)=names
    ylab="Noise type percentages"
    main="Noise type composition"
    if(nt.predef){
      colors=c("pink", "brown", "black", "white")
    }else{
      colors=c("pink", "brown", "black","white", "grey")
    }
    if(summary.type=="noise"){
      rownames(composition)=colors
    }else if(summary.type=="autocor"){
      rownames(composition)=c("autocorbin1","autocorbin2","autocorbin3","autocorbin4","unclass")
      ylab="Maximal autocorrelation bin percentages"
      main="Maximal autocorrelation bin composition"
      colors=c("white","lightblue","blue","darkblue","gray")
    }else if(summary.type=="hurst"){
      rownames(composition)=c("lowhurst","middlehurst","highhurst","veryhighhurst","unclass")
      ylab="Hurst exponent bin percentages"
      main="Hurst exponent bin composition"
      colors=c("white","orange","red","darkred","gray")
    }
    if(custom.header != ""){
      main=custom.header
    }
    if(useGgplot==TRUE){
      id=NA
      value=NA
      variable=NA
      mat=rbind(c(1:length(names)),composition)
      rownames(mat)=c("id",rownames(composition))
      df=as.data.frame(t(mat))
      df.m=reshape2::melt(df,id.var="id")
      ggplotObj=ggplot2::ggplot(df.m, ggplot2::aes(x = id, y = value, fill = variable)) +
        ggplot2::geom_bar(stat = "identity") + ggplot2::ylab(ylab) + ggplot2::xlab("Experiment id") + ggplot2::scale_fill_manual(values=colors)
    }else{
      colnames(composition)=NULL
      # dummy columns to make place for legend
      for(dummy.index in 1:15){
        names=c(names,"")
        labelcolors=c(labelcolors,"white")
        colors=c(colors,"white")
        composition=cbind(composition,rep(NA,nrow(composition)))
      }
      par(las=2, srt=90, mar = c(5, 5, 4, 4))
      names=customizeGeneratorNames(generator.names=names)
      midpoints=barplot(composition,col=colors, ylab=ylab,main=main)
      if(no.xlabels==FALSE){
        mtext(names,col=labelcolors,side=1, cex=0.8, line=0.5, at=midpoints)
      }
      # set default par
      par(las = 1, srt=0, cex=1, mar = c(4, 5, 4, 4))
      if(summary.legend==TRUE){
        # hard-coded legend text and colors
        legend.names=c("Sigma 0.1","Sigma 0.05", "Sigma 0.01","Interval 5","Interval 10","Death rate 100","Death rate 1000")
        labelcolors=c("brown","darkgoldenrod","orange","green","blue","deeppink","red")
        legend("topright",legend=legend.names,cex=0.9, bty="n",inset=c(-0.02), y.intersp=0.6, xpd=TRUE,text.col=labelcolors) # box.col="white"
      }

    }
  }else if(type=="biplot" && ggbiplotPresent==TRUE){
    groups=as.factor(data$algorithm)
    if(nt.predef){
      #mat=cbind(data$white, data$pink, data$brown, data$black, data$autoslope, data$taylorr2, data$neutral, data$corrAll)
      #colnames(mat)=c("white","pink","brown","black","autocor","taylor.R2", "neutrality","LIMITS")
      mat=cbind(data$white, data$pink, data$brown, data$black,data$autoslope, data$taylorr2, data$neutral)
      colnames(mat)=c("white","pink","brown","black","autocor","taylor.R2", "neutrality")
    }else{
      mat=cbind(data$pink, data$brown, data$black, data$autoslope,data$taylorr2, data$neutral, data$corrAll)
      colnames(mat)=c("pink","brown","black","autocor","taylor.R2", "neutrality","LIMITS")
    }
    prin.out=stats::princomp(mat,cor=TRUE) # center & scale
    #ggplotObj=ggbiplot(prin.out, groups=groups)
  }else if(type=="pca"){
    mat=cbind(data$maxautocorbin1, data$maxautocorbin2, data$maxautocorbin3, data$maxautocorbin4)
    mat=scale(mat)
    # correlations are computed column-wise by default
    out=my.pca(mat,useCor=TRUE, components=pcs)
    res=getColorVector(data)
    colvec=res$colors
    pchvec=res$symbols
    # with intervals indicated by shape
    plot(out$projection[1,],out$projection[2,], xlim=c(-3,3),col=colvec, bg=colvec, pch=pchvec, cex=1.5, xlab="PC1", ylab="PC2", main="PCA")
    algcolors=c("blue","gray","pink","brown","orange","green","red")
    legend(x="topright",legend=unique(data$algorithm), pch = rep(16,length(unique(data$algorithm))), col=algcolors, bg="white", text.col="black")
  }else if(type=="rankabund"){
    colvec=getColorVector(data)$colors
    algcolors=c("blue","gray","pink","brown","orange","green","red")
    # colorBy not supported for all
    if(generator=="all"){
      colorBy=""
    }
    if(addInitAbund==TRUE){
      distribs$y=generateAbundances(N=100,mode=5, count=1000, k=0.5, probabs=FALSE)
      # for initial abundances
      colvec=c(colvec,"black")
      algcolors=c(algcolors,"black")
    }
    xlab="Rank"
    ylab="Abundances"
    if(norm==TRUE){
      ylab="Proportions"
    }
    main="Rank-abundance curve of last time point"
    if(generator != "all"){
      main=paste(main,", generator: ",generator,sep="")
    }
    selectedAlg=generator
    if(norm==TRUE){
      yRange=c(0,1)
    }else{
      if(generator == "all"){
        yRange = range(distribs, na.rm=T)
      }else{
        indices=which(data$algorithm==generator)
        yRange=range(distribs[, indices])
      }
    }
    # not more than 5 values for any parameter
    param.colors = c("cyan","green","blue","orange","red")
    param.col.counter=1
    param.val.vs.col=list()
    param.plot.colors=c()

    numToPlot=taxonNum
    if(is.na(taxonNum)){
      numToPlot=length(distribs[,1])
    }
    plot(distribs[1:numToPlot,1],ylim = yRange,xlab = xlab, ylab = ylab, main = main, type="n")
    for(i in 1:ncol(distribs)){
      doPlot=FALSE
      last=FALSE
      if(i == ncol(distribs)){
        last=TRUE
      }
      if(selectedAlg == "all"){
        doPlot=TRUE
      }
      if(selectedAlg == "hubbell" && colvec[i]=="gray"){
        doPlot=TRUE
      }
      if(selectedAlg == "dm" && colvec[i]=="pink"){
        doPlot=TRUE
      }
      if(selectedAlg == "ricker" && colvec[i]=="blue"){
        doPlot=TRUE
      }
      if(selectedAlg == "davida" && colvec[i]=="brown"){
        doPlot=TRUE
      }
      if(selectedAlg == "davidb" && colvec[i]=="orange"){
        doPlot=TRUE
      }
      if(selectedAlg == "soi" && colvec[i]=="green"){
        doPlot=TRUE
      }
      if(selectedAlg == "glv" && colvec[i]=="red"){
        doPlot=TRUE
      }
      if(doPlot==TRUE || (addInitAbund==TRUE && last)){
        col=colvec[i]
        if(last == FALSE && colorBy != ""){
          paramval=unlist(data[colorBy])[i]
          searchparamval=paste(colorBy,paramval,sep="")
          #print(searchparamval)
          if(searchparamval %in% names(param.val.vs.col)){
            param.col=param.val.vs.col[searchparamval]
          }else{
            param.col=param.colors[param.col.counter]
            param.val.vs.col[searchparamval]=param.col
            param.col.counter=param.col.counter+1
          }
          col=unlist(param.col)
          param.plot.colors=c(param.plot.colors,col)
        }
        distribs[,i]=sort(distribs[,i],decreasing=TRUE)
        values=distribs[,i]
        if(norm==TRUE){
          values=values/sum(values)
        }
        if(!is.na(taxonNum)){
          values=values[1:taxonNum]
        }
        if(pch != ""){
          lines(values,col = col, pch=pch, type="b")
        }else{
          lines(values,col = col)
        }
      }
    }
    print(param.plot.colors)
    if(generator=="all"){
      if(addInitAbund==TRUE){
        legend(x="topright",legend=c(as.character(unique(data$algorithm)),"y"), pch = rep(15,(length(unique(data$algorithm))+1)), col=algcolors, bg="white", text.col="black")
      }else{
        legend(x="topright",legend=unique(data$algorithm), pch = rep(15,length(unique(data$algorithm))), col=algcolors, bg="white", text.col="black")
      }
    }else{
      if(colorBy != ""){
        legend(x="topright",legend=names(param.val.vs.col), pch = rep(15,length(names(param.val.vs.col))), col=unique(param.plot.colors), bg="white", text.col="black")
      }
    }
  }
  if(!is.null(ggplotObj) && makeggplot==TRUE){
    plot(ggplotObj)
  }
  ggplotObj
}

# assign more beautiful abbreviations to generators
# to be used prior to plotting
# as many entries expected as experiments done
customizeGeneratorNames<-function(generator.names=NULL){
    soi.indices=which(generator.names=="soi")
    ricker.indices=which(generator.names=="ricker")
    glv.indices=which(generator.names=="glv")
    dm.indices=which(generator.names=="dm")
    stoola.indices=which(generator.names=="davida")
    stoolb.indices=which(generator.names=="davidb")
    hubbell.indices=which(generator.names=="hubbell")
    custom.generator.names=generator.names
    ### customization
    custom.generator.names[soi.indices]="SOI"
    custom.generator.names[hubbell.indices]="Hubbell"
    custom.generator.names[stoola.indices]="Stool A"
    custom.generator.names[stoolb.indices]="Stool B"
    custom.generator.names[dm.indices]="DM"
    custom.generator.names[glv.indices]="gLV"
    custom.generator.names[ricker.indices]="Ricker"
    return(custom.generator.names)
}


# filter out intervals > 1 and/or death rate > 100
# returns the filtered data frame containing only the data necessary for the selected plot
filterData<-function(data, type="boxplot", summary.type="noise", property="pink", colorBy="interval", skipIntervals=FALSE, skipHighDeathrate=FALSE, skipGenerators=c()){
  keepIndices=c()
  if(skipIntervals==TRUE){
    keepIndices=which(data$interval==1)
  }else{
    keepIndices=c(1:length(data$algorithm))
  }
  if(skipHighDeathrate==TRUE){
    deaths=data$deaths
    deaths[is.na(deaths)]=0
    temp=which(deaths<1000)
    keepIndices=intersect(keepIndices,temp)
  }
  if(length(skipGenerators)>0){
    for(generator in skipGenerators){
      generators=data$algorithm
      temp=which(generators!=generator)
      keepIndices=intersect(keepIndices,temp)
    }
  }
  if(type=="summary"){
    if(summary.type=="noise"){
      filteredData=list(data[[colorBy]][keepIndices],data$deaths[keepIndices],data$sigma[keepIndices],data$interval[keepIndices],data$algorithm[keepIndices], data$pink[keepIndices],data$brown[keepIndices],data$black[keepIndices])
      names(filteredData)=c(colorBy,"deaths","sigma","interval","algorithm","pink","brown","black")
    }else if(summary.type=="autocor"){
      filteredData=list(data[[colorBy]][keepIndices],data$deaths[keepIndices],data$sigma[keepIndices],data$interval[keepIndices],data$algorithm[keepIndices], data$maxautocorbin1[keepIndices], data$maxautocorbin2[keepIndices],data$maxautocorbin3[keepIndices],data$maxautocorbin4[keepIndices])
      names(filteredData)=c(colorBy,"deaths","sigma","interval","algorithm","maxautocorbin1","maxautocorbin2","maxautocorbin3","maxautocorbin4")
    }else if(summary.type=="hurst"){
      filteredData=list(data[[colorBy]][keepIndices],data$deaths[keepIndices],data$sigma[keepIndices],data$interval[keepIndices],data$algorithm[keepIndices], data$lowhurst[keepIndices], data$middlehurst[keepIndices],data$highhurst[keepIndices],data$veryhighhurst[keepIndices])
      names(filteredData)=c(colorBy,"deaths","sigma","interval","algorithm","lowhurst","middlehurst","highhurst","veryhighhurst")
    }
  }else if(type=="boxplot"){
    filteredData=list(data$algorithm[keepIndices],data[[property]][keepIndices], data[[colorBy]][keepIndices])
    names(filteredData)=c("algorithm",property,colorBy)
  }else if(type=="pca"){
    filteredData=list(data$interval[keepIndices],data$algorithm[keepIndices], data$maxautocorbin1[keepIndices], data$maxautocorbin2[keepIndices],data$maxautocorbin3[keepIndices],data$maxautocorbin4[keepIndices])
    names(filteredData)=c("interval","algorithm","maxautocorbin1","maxautocorbin2","maxautocorbin3","maxautocorbin4")
  }
  filteredData = as.data.frame(filteredData)
  return(filteredData)
}

# Extract generator-specific colors and shapes from the result table
getColorVector<-function(table){
  colvec=c()
  pchvec=c()
  for(i in 1:length(table$algorithm)){
    col=""
    # http://www.statmethods.net/advgraphs/parameters.html
    pchar=0
    if(table$interval[i]=="1"){
      pchar=21 # circle
    }else if(table$interval[i] == "5"){
      pchar=22 # square
    }else if(table$interval[i] == "10"){
      pchar=23 # diamond
    }
    pchvec=c(pchvec,pchar)
    #intervalvec=c(intervalvec,intervalcol)
    if(table$algorithm[i]=="ricker"){
      col="blue"
    }else if(table$algorithm[i]=="glv"){
      col="red"
    }else if(table$algorithm[i]=="soi"){
      col="green"
    }else if(table$algorithm[i]=="dm"){
      col="pink"
    }else if(table$algorithm[i]=="hubbell"){
      col="gray"
    }else if(table$algorithm[i]=="davida"){
      col="brown"
    }else if(table$algorithm[i]=="davidb"){
      col="orange"
    }
    colvec=c(colvec,col)
  }
  res=list(colvec,pchvec)
  names(res)=c("colors","symbols")
  return(res)
}

# taken from: http://stackoverflow.com/questions/18509527/first-letter-to-upper-case
firstup <- function(x) {
  substr(x, 1, 1) <- toupper(substr(x, 1, 1))
  x
}

##############################

# task: principal component analysis

# input: x = matrix
#        useCor = boolean, true if correlation should be used (recommended if x is already standardized)
#        verbose = verbosity
#        plot = plot projection of data in two-dimensional space spanned by two components (by default first and second)
#        manual = manually identify datapoints in a plot (to set their names)
#        components = the components (eigenvectors) to use for the plot
#        colvec = vector containing colors to color data points in plot (by default NULL)
#        save = save result in given location
#        location = file or directory/file to save result

# output: result with slots for projection (x projected on subspace), V (eigenvectors, columnwise),
#         d (eigenvalues) and Var (percentage of total variation explained by principal component)

my.pca<-function(x, useCor=F, verbose=F, plot=F, manual=F,components=c(1,2), colvec=NULL, save=F, location="PCAresult.dat"){

  # calculate eigen values and vectors of correlation matrix
  # correlation matrix used if x already divided by standard deviation
  # (covariance of standardized variables equals correlation)
  if(useCor){
    eig=eigen(cor(x, use="pairwise.complete.obs"))
  }else{
    eig=eigen(cov(x, use="pairwise.complete.obs"))
  }
  # eigen values
  d=eig[[1]]
  # eigen vectors (by column)
  V=eig[[2]]

  # calculate total variation and variances explained by the principal components
  total=sum(d)
  i=1
  Var=matrix(0,ncol(x),1)
  while(i<=ncol(x)){
    Var[i,1]=d[i]/total*100
    i=i+1
  }
  dimnames(Var)=list(c(1:ncol(x)),c("percentage of total variation"))
  if(verbose){
    print(Var)
  }

  # calculate projection of x on two-dimensional subspace spanned by selected eigenvectors
  V.project = cbind(V[,components[1]],V[,components[2]])
  x.trans=t(V.project)%*%t(x)

  #Plot
  if(plot){
    par(cex=0.5)
    title=paste("Data in PC ",components[1],"/",components[2]," subspace",sep=" ")
    xlab=paste("PC ",components[1])
    ylab=paste("PC ",components[2])
    if(is.null(colvec)){
      plot(x.trans[1,],x.trans[2,],xlab=xlab,ylab=ylab,main=title)
    }else{
      if(nrow(x)!=length(colvec)){
        print("Error! Given color vector should contain as many colors as x has rows!")
      }
      plot(x.trans[1,],x.trans[2,],xlab=xlab,ylab=ylab, col=colvec)
    }
    text(x.trans[1,],x.trans[2,],pos=2,labels=rownames(x))
    # manually identify data points
    if(manual){
      identify(x.trans[1,],x.trans[2,],labels=rownames(x),plot=T)
    }
  }
  # return results
  result=list()
  result$projection = x.trans
  result$V = V
  result$d = d
  result$Var = Var
  # save result
  if(save){
    cat(result,file=location)
  }
  result
}
