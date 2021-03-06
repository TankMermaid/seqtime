% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/interpolate.R
\name{interpolate}
\alias{interpolate}
\title{Time Series Interpolation}
\usage{
interpolate(x, interval = NA, time.index = NA, time.vector = c(),
  method = "stineman", groups = c(), negzero = FALSE)
}
\arguments{
\item{x}{the time series matrix, rows are objects and columns are time points}

\item{interval}{the target intervals to be present after interpolation}

\item{time.index}{the row index holding time points}

\item{time.vector}{the vector holding time points}

\item{method}{fmm, periodic, natural, hyman or monoH.FC (spline), scaledstineman, stineman or parabola (stinterp)}

\item{groups}{a vector with group assignments and as many entries as there are samples}

\item{negzero}{set negative values (can be introduced by interpolation) to zero}
}
\value{
interpolated time series
}
\description{
Wrapper function to interpolate a time series. If groups are specified, each
group is processed separately. The time points of each group are supposed to be in chronological order.
}
\details{
If no interval is provided, the intervals in the time vector are computed and the most frequent one is taken as the interval.
The default interpolation method is stineman. Note that interpolation can introduce negative values in the abundance matrix.
}
\examples{
  data("david_stoolA_otus")
  data("david_stoolA_metadata")
  days=david_stoolA_metadata[1,]
  sorted=sort(apply(david_stoolA_otus,1,sum),decreasing=TRUE,index.return=TRUE)
  davida.top=david_stoolA_otus[sorted$ix[1:100],]
  tsplot(interpolate(davida.top,time.vector=days))
}
