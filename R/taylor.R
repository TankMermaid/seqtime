#' @title Plot relationship between row mean and row variance
#'
#' @description The power law relationship between variance and mean is known as Taylor's law, which is
#' defined as: \eqn{var(Y) = a*mean(Y)^b}. We can obtain the power as the slope in log-scale: \eqn{log(var(Y)) = log(a)+b*log(mean(Y))}
#'
#' @param x a matrix
#' @param type the type of plot to do: mean.var (mean vs variance), boxplot (row-wise), taylor (powerlaw fitted to mean vs variance)
#' @param pseudo add a pseudo count to deal with zeros in log-log plot (for type=taylor)
#' @param col the color of the dots
#' @param header header string
#' @param plot whether to do the plot
#' @return for type taylor, the slope, p-value and adjusted R2 of the Taylor law are returned (slope, pval, adjR2)
#' @references L.R. Taylor (1961). Aggregation, variance and the mean. Nature 189, 732-735.
#' @export

taylor<-function(x, type="taylor", pseudo=0, col="black", header="", plot=TRUE){
  pval=NA
  slope=NA
  adjR2=NA
  if(type == "boxplot"){
    #par(las=3, cex=0.5)
    if(plot == TRUE){
      boxplot(t(x), ylab="Abundances", xaxt='n', ann=FALSE, border=col)
    }
  }else{
    means=apply(x,1, mean, na.rm=TRUE)
    vars=apply(x,1, var, na.rm=TRUE)
    if(type == "taylor"){
      logvars=log(vars+pseudo)
      logmeans=log(means+pseudo)
      reg.data=data.frame(logvars,logmeans)
      linreg = lm(formula = logvars~logmeans)
      # print(paste("Intercept:",linreg$coefficients[1]))
      # print(paste("Slope:",linreg$coefficients[2]))
      slope=linreg$coefficients[2]
      sum=summary(linreg)
      adjR2=sum$adj.r.squared
      #print(paste("Adjusted R2:",sum$adj.r.squared))
      pval=1-pf(sum$fstatistic[1], sum$fstatistic[2], sum$fstatistic[3])
      # print(paste("P-value:",pval))
      if(plot == TRUE){
        plot(logmeans,logvars, xlab="Log(mean)", ylab="Log(variance)", main=paste("Taylor's law",header,"\np-value:",round(pval,3),", adjusted R2:",round(sum$adj.r.squared,2),", slope:",round(linreg$coefficients[2],2)),type="p",pch="+",col=col)
        abline(linreg,bty="n",col="red")
      }
    }else if(type == "mean.var"){
      if(plot==TRUE){
        plot(means,vars,xlab="Mean", ylab="Variance", main="Mean versus variance",type="p",pch="+",col=col)
      }
    } # mean variance end
  } # no box plot
  res=list(slope,pval,adjR2,logmeans,logvars)
  names(res)=c("slope","pval","adjR2","logmeans","logvars")
  return(res)
}
