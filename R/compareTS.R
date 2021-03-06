#' @title Community Time Series Comparison
#'
#' @description Compute properties of community time series generated with generateTS.
#'
#' @details If infotheo is installed, the entropy will be also computed. Noise types are computed with smooth set to true.
#' The neutrality test is carried out with ntests set to 500 and method logitnorm.
#'
#' @param input.folder the folder where results (settings and time series) of function generateTS are stored.
#' @param expIds the experiment identifiers of time series to be considered
#' @param modif.folder the folder with time series sub-sets as generated by sliceTS.R or with noisy time series as generated by addNoise.R (settings are read in from input.folder)
#' @param modif modification (shared name of time series in modif.folder, sliced for time series sub-sets and pois/multi for time series with Poisson or multinomial noise, respectively)
#' @param testNeutral test neutrality (requires libraries WrightFisher and logitnorm)
#' @param sliceDef consider the time series sub-set defined by the given start and end time point for property computation, an end time point of NA means that the entire time series is considered, a single value T in the sliceDef vector means that the last T time points are considered; timeDecaySliceDef and varEvolSliceDef refer to the outcome of sliceDef
#' @param epsilon allowed deviation from the expected slope for noise type identification
#' @param predef recognize noise types with predefined slope boundaries (see identifyNoisetypes for details)
#' @param detrend remove linear trends before computing the periodogram (recommended)
#' @param norm normalize time series by dividing each entry in a sample by the sum of its sample; if norm is true, entropy computation is omitted
#' @param hurstBins binning thresholds for Hurst exponent (three thresholds required for four bins)
#' @param maxautocorBins binning thresholds for maximal autocorrelation (three thresholds required for four bins)
#' @param timeDecaySliceDef the time series subset considered to compute the time decay, a vector with the start and the end time point (if the end time point is NA, the entire time series is used)
#' @param varEvolSliceDef (optional, by default not computed) the time series subset considered to compute the evolution of variance, a vector with the start and the end time point (if the end time point is NA, the entire time series is used)
#' @param radSliceDef (optional, by default not computed) the time series subset considered to analyse the (non-normalized also when norm is enabled) species abundance versus rank curve, a vector with the start and the end time point (if the end time point is NA, the entire time series is used); cannot be used together with sliceDef
#' @param returnDistribs return distributions at the final time point (no time series properties are computed, cannot be used together with returnTS)
#' @param returnTS return the time series (no time series properties are computed, cannot be used together with returnDistribs)
#' @return a table with experiment parameters (algorithm, connectance, sigma, theta and so on) and time series properties (noise types percentages, slope of Taylor's law etc.); if returnDistrib is true, a list with the abundances at the last time point, if returnTS is true, a list with the time series
#' @export

compareTS <- function(input.folder="",expIds=c(), modif.folder="", modif="", testNeutral=FALSE, sliceDef=c(1,NA), epsilon=0.2, predef=FALSE, detrend=TRUE, norm=FALSE, hurstBins=c(0.5,0.7,0.9), maxautocorBins=c(0.3,0.5,0.8), timeDecaySliceDef=c(1,50), varEvolSliceDef=c(), radSliceDef=c(), returnDistribs=FALSE, returnTS=FALSE){

  # infotheo needed for entropy computation
  infotheoThere=FALSE
  # https://stat.ethz.ch/pipermail/r-help/2005-September/078958.html
  searchInfotheo=length(grep(paste("^package:","infotheo", "$", sep=""), search()))
  if(searchInfotheo>0){
    infotheoThere=TRUE
  }else{
    if(norm==FALSE){
      print("Please install/load infotheo if you want to compute the entropy of non-normalized time series.")
    }
  }

  # neutrality test dependencies
  wfThere=FALSE
  # https://stat.ethz.ch/pipermail/r-help/2005-September/078958.html
  searchWf=length(grep(paste("^package:","WrightFisher", "$", sep=""), search()))
  if(searchWf>0){
    wfThere=TRUE
  }else{
    if(testNeutral){
      warning("Please install/load WrightFisher if you want to test for neutrality. Test is not carried out.")
    }
  }
  logitnormThere=FALSE
  # https://stat.ethz.ch/pipermail/r-help/2005-September/078958.html
  searchLN=length(grep(paste("^package:","logitnorm", "$", sep=""), search()))
  if(searchLN>0){
    logitnormThere=TRUE
  }else{
    if(testNeutral){
      warning("Please install/load logitnorm if you want to test for neutrality. Test is not carried out.")
    }
  }

  if(testNeutral && !norm){
    stop("Data are supposed to be normalized for neutrality test.")
  }

  if(length(hurstBins) != 3){
    stop("Three Hurst bin thresholds required!")
  }

  if(length(sliceDef)>0 && length(radSliceDef)>0){
    stop("radSliceDef and sliceDef cannot be used together.")
  }

  if(length(maxautocorBins) != 3){
    stop("Three maximal autocorrelation bin thresholds required!")
  }

  if(returnDistribs==TRUE && returnTS==TRUE){
    stop("Cannot use returnDistribs and returnTS together.")
  }

  if(input.folder != ""){
    if(!file.exists(input.folder)){
      stop(paste("The input folder",input.folder,"does not exist!"))
    }
    input.settings.folder=file.path(input.folder,"settings")
    if(!file.exists(input.settings.folder)){
      stop("The input folder does not have a settings subfolder!")
    }
    if(modif.folder == ""){
      input.timeseries.folder=file.path(input.folder,"timeseries")
      if(!file.exists(input.timeseries.folder)){
        stop("The input folder does not have a time series subfolder!")
      }
    }else{
      if(!file.exists(modif.folder)){
        stop("The folder with sliced time series does not exist!")
      }
    }
  }else{
    stop("Please provide the input folder!")
  }

  # experiment properties
  taxa=c()
  samples=c()
  peps=c()
  initmode=c()
  connectances=c()
  algorithms=c()
  sigmas=c()
  thetas=c()
  migrations=c()
  deathrates=c()
  individuals=c()
  samplingfreqs=c()

  # time series properties
  taylorslopes=c()
  taylorR2=c()
  timedecayslopes=c()
  timedecayR2=c()
  varevolslopes=c()
  varevolR2=c()
  percentblack=c()
  percentbrown=c()
  percentpink=c()
  percentwhite=c()
  thetaprobs=c()
  neutralityPvals=c()
  # from lowest to highest maximal autocorrelation
  binA4Name=paste("autocor",maxautocorBins[3],"Inf",sep="")
  binA3Name=paste("autocor",maxautocorBins[2],maxautocorBins[3],sep="")
  binA2Name=paste("autocor",maxautocorBins[1],maxautocorBins[2],sep="")
  binA1Name=paste("autocor","negInf",maxautocorBins[1],sep="")
  percentmaxautocorbin1=c()
  percentmaxautocorbin2=c()
  percentmaxautocorbin3=c()
  percentmaxautocorbin4=c()
  binH4Name=paste("hurst",hurstBins[3],"Inf",sep="")
  binH3Name=paste("hurst",hurstBins[2],hurstBins[3],sep="")
  binH2Name=paste("hurst",hurstBins[1],hurstBins[2],sep="")
  binH1Name=paste("hurst","negInf",hurstBins[1],sep="")
  lowHursts=c()
  middleHursts=c()
  highHursts=c()
  veryHighHursts=c()
  entropy=c()
  autoslopes=c()
  saddistribsvegan=c()
  saddistribs=c()
  saddistribsfitscore=c()
  saddistribsfitscorevegan=c()

  Algorithm=""
  Input_experiment_identifier=NA
  Sampling_frequency=NA
  init_abundance_mode=NA
  theta=NA
  immigration_rate_Hubbell=NA
  deathrate_Hubbell=NA

  # distribution list
  distribList = list()

  # time series list
  tsList = list()

  # collect time series properties
  for(expId in expIds){

    print(paste("Processing identifier",expId))

    input.settings.name=paste(expId,"settings",sep="_")
    input.settings.expId.folder=file.path(input.settings.folder,input.settings.name)
    #print(input.settings.expId.folder)
    if(!file.exists(input.settings.expId.folder)){
      stop("The input settings folder does not have a subfolder for the input experiment identifier!")
    }

    if(modif.folder == ""){
      input.timeseries.name=paste(expId,"timeseries",sep="_")
      input.timeseries.expId.folder=file.path(input.timeseries.folder,input.timeseries.name)
      if(!file.exists(input.timeseries.expId.folder)){
        stop("The input time series folder does not have a subfolder for the input experiment identifier!")
      }
    }

    # read settings file
    input.settings.expId.file=paste(expId,"settings.txt",sep="_")
    settings.path=file.path(input.settings.expId.folder,input.settings.expId.file)
    if(!file.exists(settings.path)){
      stop(paste("The settings file",settings.path,"does not exist!"))
    }
    source(settings.path, local=TRUE)

    algorithms=c(algorithms,Algorithm)
    samplingfreqs=c(samplingfreqs,Sampling_frequency)

    # read interaction matrix
    if(returnDistribs == FALSE && returnTS==FALSE){
      if(Algorithm == "ricker" || Algorithm == "soc" || Algorithm == "soi" || Algorithm == "glv"){
        source.expId = expId
        interactionmatrix.folder=input.settings.expId.folder
        # interaction matrix for current experiment was read from another experiment
        if(!is.na(Input_experiment_identifier) && Input_experiment_identifier!=FALSE){
          source.expId=Input_experiment_identifier
          source.expId.folder=paste(source.expId,"settings",sep="_")
          interactionmatrix.folder=file.path(input.settings.folder,source.expId.folder)
        }
        A.name=paste(source.expId,"interactionmatrix.txt",sep="_")
        input.path.A=file.path(interactionmatrix.folder,A.name)
        print(paste("Reading interaction matrix from:",input.path.A,sep=" "))
        A=read.table(file=input.path.A,sep="\t",header=FALSE)
        A=as.matrix(A)
        # the requested and target PEP differ
        peps=c(peps,round(getPep(A),2))
        connectances=c(connectances,getConnectance(A))
      }else{
        peps=c(peps,NA)
        connectances=c(connectances,NA)
      }
    }

    initmode=c(initmode,init_abundance_mode)

    # read algorithm-specific parameters
    if(Algorithm == "ricker"){
      sigmas=c(sigmas,sigma)
    }else{
      sigmas=c(sigmas,NA)
    }
    if(Algorithm == "dm"){
      thetas=c(thetas,theta)
    }else{
      thetas=c(thetas,NA)
    }
    if(Algorithm == "hubbell"){
      migrations=c(migrations,immigration_rate_Hubbell)
      deathrates=c(deathrates, deathrate_Hubbell)
    }else{
      migrations=c(migrations,NA)
      deathrates=c(deathrates,NA)
    }
    if(Algorithm == "soc" || Algorithm == "hubbell"){
      individuals=c(individuals,I)
      #print(paste("individuals",I))
    }else{
      individuals=c(individuals,NA)
    }

    # read time series file
    if(modif.folder == ""){
      ts.name=paste(expId,"timeseries.txt",sep="_")
      input.path.ts=file.path(input.timeseries.expId.folder,ts.name)
    }else{
      ts.name=paste(expId,modif,"timeseries.txt",sep="_")
      input.path.ts=file.path(modif.folder, ts.name)
    }
    print(paste("Reading time series from:",input.path.ts,sep=" "))
    ts=read.table(file=input.path.ts,sep="\t",header=FALSE)
    ts=as.matrix(ts)
    # store non-normalized samples for RAD testing
    if(length(radSliceDef)==2){
      startTD=radSliceDef[1]
      stopTD=radSliceDef[2]
      if(is.na(stopTD)){
        stopTD=ncol(ts)
      }
      if(ncol(ts) < startTD){
        warning(paste("Time series",expId,"has less samples (namely",ncol(ts),") than the given start point for RAD properties! The first time point is used instead."))
        startTD=1
      }
      if(ncol(ts) < stopTD){
        warning(paste("Time series",expId,"has less samples (namely",ncol(ts),") than the given end point for RAD properties! The last time point is used instead."))
        stopTD=ncol(ts)
      }
      sadSlice=ts[,startTD:stopTD]
    }
    lastSample=ts[,ncol(ts)]
    if(norm==TRUE){
      ts=seqtime::normalize(ts)
    }
    if(sliceDef[1]>1 || !is.na(sliceDef[2])){
      if(length(sliceDef)==1){
        subsetStop=ncol(ts)
        subsetStart=subsetStop-sliceDef[1]
        if(subsetStart < 1){
          warning(paste("Time series",expId,"has less samples (namely",ncol(ts),") than the given start point! The first time point is used instead!"))
          subsetStart=1
        }
      }else{
        subsetStart=sliceDef[1]
        subsetStop=sliceDef[2]
        if(subsetStop > ncol(ts)){
          warning(paste("Time series",expId,"has less samples (namely",ncol(ts),") than the given end point! The last time point is used instead!"))
          subsetStop=ncol(ts)
        }
        if(is.na(sliceDef[2])){
          subsetStop=ncol(ts)
        }
      }
      ts=ts[,subsetStart:subsetStop]
    }
    N=nrow(ts)
    print(paste("Read time series with",N,"taxa and",ncol(ts),"samples."))
    onePerc=N/100
    taxa=c(taxa,N)
    samples=c(samples,ncol(ts))

    if(returnDistribs == FALSE && returnTS==FALSE){
      # entropy
      if(norm==FALSE && infotheoThere==TRUE){
        # discretization needed (also for David data, because of interpolation)
        if(Algorithm=="glv" || Algorithm == "ricker" || Algorithm == "davida" || Algorithm == "davidb"){
          disc=infotheo::discretize(t(ts),disc="equalwidth")
          ent=infotheo::entropy(disc)
        }else{
          ent=entropy(t(ts))
        }
        entropy=c(entropy,ent)
      }else{
        entropy=c(entropy,NA)
      }

      if(testNeutral && wfThere && logitnormThere && norm){
        # runs logitnorm by default
        neutralityPvals=c(neutralityPvals, WrightFisher::NeutralCovTest(t(ts), ntests=500))
      }else{
        neutralityPvals=c(neutralityPvals,NA)
      }

      # auto-correlation vs species number slope
      autocorOut=autocorVsTaxonNum(ts,lag=1,plot=FALSE)
      autoslopes=c(autoslopes,autocorOut$slope)

      # bin Hurst exponent
      hursts=binByMemory(ts,thresholds=hurstBins,method="hurst")
      lowHursts=c(lowHursts,length(hursts[[binH1Name]])/onePerc)
      middleHursts=c(middleHursts,length(hursts[[binH2Name]])/onePerc)
      highHursts=c(highHursts,length(hursts[[binH3Name]])/onePerc)
      veryHighHursts=c(veryHighHursts,length(hursts[[binH4Name]])/onePerc)

      # bin maximal autocorrelations
      autocorBins=binByMemory(ts,thresholds=maxautocorBins,method="autocor")
      percentmaxautocorbin4=c(percentmaxautocorbin4, length(autocorBins[[binA4Name]])/onePerc)
      percentmaxautocorbin3=c(percentmaxautocorbin3, length(autocorBins[[binA3Name]])/onePerc)
      percentmaxautocorbin2=c(percentmaxautocorbin2, length(autocorBins[[binA2Name]])/onePerc)
      percentmaxautocorbin1=c(percentmaxautocorbin1, length(autocorBins[[binA1Name]])/onePerc)

      # calculate taylor's law slope
      taylorRes=taylor(ts,type="taylor",plot=FALSE, pseudo=0.0000001)
      noisetypesRes=identifyNoisetypes(ts,abund.threshold = 0, epsilon=epsilon, smooth=TRUE,predef=predef, detrend=detrend)

      taylorslopes=c(taylorslopes,taylorRes$slope)
      taylorR2=c(taylorR2,taylorRes$adjR2)
      percentbrown=c(percentbrown,length(noisetypesRes$brown)/onePerc)
      percentpink=c(percentpink,length(noisetypesRes$pink)/onePerc)
      percentwhite=c(percentwhite,length(noisetypesRes$white)/onePerc)
      percentblack=c(percentblack,length(noisetypesRes$black)/onePerc)

      # species abundance versus rank distribution shape
      if(length(radSliceDef)==2){
        # scale abundances to integers
        if(Algorithm=="ricker" || Algorithm=="glv"){
          sadSlice=round(sadSlice*1000)
        }
        else if(Algorithm=="davida" || Algorithm=="davidb"){
          sadSlice=round(sadSlice)
        }
        sad.out.distrib=rad(sadSlice,remove.zeros=TRUE, fit.distrib=TRUE, plot=FALSE)
        sad.out.vegan=rad(sadSlice,remove.zeros=TRUE, fit.rad=TRUE, plot=FALSE)
        saddistribsvegan=c(saddistribsvegan,sad.out.vegan$distrib)
        saddistribs=c(saddistribs,sad.out.distrib$distrib)
        saddistribsfitscorevegan=c(saddistribsfitscorevegan,sad.out.vegan$score)
        saddistribsfitscore=c(saddistribsfitscore,sad.out.distrib$score)
        # fit neutral model to slice
        thetaprobs=c(thetaprobs,rad(sadSlice, remove.zeros = TRUE,fit.neutral = TRUE,plot=FALSE)$thetaprob)

      }else{
        if(length(radSliceDef)>0){
          warning("The RAD slice is not defined correctly!")
        }
        saddistribsvegan=c(saddistribsvegan,NA)
        saddistribs=c(saddistribs,NA)
        saddistribsfitscore=c(saddistribsfitscore,NA)
        saddistribsfitscorevegan=c(saddistribsfitscorevegan,NA)
        # if no RAD slice defined: fit neutral model to last sample
        if(Algorithm=="ricker" || Algorithm=="glv"){
          lastSample=round(lastSample*1000)
        }
        else if(Algorithm=="davida" || Algorithm=="davidb"){
          lastSample=round(lastSample)
        }
        thetaprobs=c(thetaprobs,rad(lastSample,remove.zeros = TRUE,fit.neutral = TRUE,plot=FALSE)$thetaprob)
      }

      # evolution of variance
      if(length(varEvolSliceDef)==2){
        startTD=varEvolSliceDef[1]
        stopTD=varEvolSliceDef[2]
        if(is.na(stopTD)){
          stopTD=ncol(ts)
        }
        if(ncol(ts) < startTD){
          stop(paste("Time series",expId,"has less samples (namely",ncol(ts),") than the given start point for variance evolution!"))
        }
        if(ncol(ts) < stopTD){
          warning(paste("Time series",expId,"has less samples (namely",ncol(ts),") than the given end point for variance evolution! The last time point is used instead!"))
          stopTD=ncol(ts)
        }
        varEvolSlice=ts[,startTD:stopTD]
        varEvolRes=varEvol(varEvolSlice, plot=FALSE)
        varevolslopes=c(varevolslopes,varEvolRes$slope)
        varevolR2=c(varevolR2,varEvolRes$adjR2)
      }else{
        if(length(varEvolSliceDef)>0){
          warning("The variance evolution slice is not defined correctly!")
        }
        varevolslopes=c(varevolslopes,NA)
        varevolR2=c(varevolR2,NA)
      }

      # time decay
      if(length(timeDecaySliceDef)==2){
        startTD=timeDecaySliceDef[1]
        stopTD=timeDecaySliceDef[2]
        if(is.na(stopTD)){
          stopTD=ncol(ts)
        }
        if(ncol(ts) < startTD){
          stop(paste("Time series",expId,"has less samples (namely",ncol(ts),") than the given start point for the time decay!"))
        }
        if(ncol(ts) < stopTD){
          warning(paste("Time series",expId,"has less samples (namely",ncol(ts),") than the given end point for the time decay! The last time point is used instead!"))
          stopTD=ncol(ts)
        }
        timeDecaySlice=ts[,startTD:stopTD]
        timedecayRes=timeDecay(timeDecaySlice, plot=FALSE, logdissim=TRUE, logtime=TRUE)
        timedecayslopes=c(timedecayslopes,timedecayRes$slope)
        timedecayR2=c(timedecayR2,timedecayRes$adjR2)
      }else{
        warning("The time decay slice is not defined correctly!")
        timedecayslopes=c(timedecayslopes,NA)
        timedecayR2=c(timedecayR2,NA)
      }
    }else if(returnDistribs==TRUE){
      # last column
      name=paste("exp",expId,sep="")
      distribList[[name]]=ts[,ncol(ts)]
    }else if(returnTS==TRUE){
      name=paste("exp",expId,sep="")
      tsList[[name]]=ts
    }
  } # end loop over experiments

  # assemble table
  if(returnDistribs == FALSE && returnTS == FALSE){
    resulttable=list(expIds,samples,algorithms,samplingfreqs,initmode,peps,connectances,sigmas,thetas,migrations,individuals, deathrates,entropy,taylorslopes,taylorR2, percentblack,percentbrown,percentpink,percentwhite, percentmaxautocorbin1,percentmaxautocorbin2,percentmaxautocorbin3,percentmaxautocorbin4, lowHursts, middleHursts, highHursts,veryHighHursts, timedecayslopes, timedecayR2, varevolslopes, varevolR2, autoslopes, neutralityPvals, saddistribs, saddistribsvegan, saddistribsfitscore, saddistribsfitscorevegan, thetaprobs)
    names(resulttable)=c("id","samplenum","algorithm","interval","initabundmode","pep","c","sigma","theta","m","individuals","deaths","entropy","taylorslope","taylorr2","black","brown","pink","white","maxautocorbin1","maxautocorbin2","maxautocorbin3","maxautocorbin4", "lowhurst","middlehurst","highhurst","veryhighhurst","timedecayslope","timedecayr2","varevolslope","varevolr2","autoslope","neutral","raddistrib","raddistribvegan","radfitscore","radfitscorevegan","thetaprobs")
  }else if(returnDistribs == TRUE){
    resulttable=distribList
  }else if(returnTS == TRUE){
    resulttable=tsList
  }
  return(resulttable)
}
