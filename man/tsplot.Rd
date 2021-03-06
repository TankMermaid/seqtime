% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tsplot.R
\name{tsplot}
\alias{tsplot}
\title{Time Series Plot}
\usage{
tsplot(x, time.given = FALSE, num = nrow(x), sample.points = c(),
  mode = "lines", dist = "bray", my.color.map = list(),
  identifyPoints = FALSE, topN = 10, groups = c(), hideGroups = c(),
  legend = FALSE, labels = c(), noLabels = FALSE, centroid = FALSE,
  perturb = NULL, ...)
}
\arguments{
\item{x}{the matrix of time series}

\item{time.given}{if true, then the column names are supposed to hold the time units}

\item{num}{the number of rows to plot (starting from the first row)}

\item{sample.points}{indicate sample points (only for lines)}

\item{mode}{lines (default), pcoa (a PCoA plot with arrows showing the community trajectory) or bars (a stacked barplot for each sample)}

\item{dist}{the distance to use for the PCoA plot}

\item{my.color.map}{map of taxon-specific colors, should match row names (only for bars) or group names (only for lines)}

\item{identifyPoints}{click at points in the PCoA plot to identify them (using function identify), not active when noLabels is TRUE}

\item{topN}{number of top taxa to be plotted for mode bars}

\item{groups}{group membership vector; for mode bars and pcoa refers to samples; for mode lines refers to taxa; there are as many entries in the group membership vector as samples or taxa; taxa/samples are assumed to be ordered by groups}

\item{hideGroups}{compute PCoA with all data, but do not show members of selected groups; expects one integer per group and consistency with groups parameter, only supported for mode pcoa}

\item{legend}{add a legend}

\item{labels}{use the provided labels in the PCoA plot}

\item{noLabels}{do not use any labels in the PCoA plot}

\item{centroid}{draw PCoA plot with a centroid (groups are ignored)}

\item{perturb}{a perturbation object (adds polygons in mode lines highlighting the perturbation periods, colors labels in mode bars and colors dots in the PCoA plot)}

\item{\\dots}{Additional arguments passed to plot()}
}
\description{
Plot the time series row-wise.
}
\examples{
N=50
A=modifyA(generateA(N, c=0.1, d=-1),perc=70,strength="uniform",mode="negpercent")
out.ricker=ricker(N,A=A,y=generateAbundances(N,mode=5,prob=TRUE),K=rep(0.1,N), sigma=-1,tend=500)
tsplot(out.ricker, main="Ricker")
tsplot(out.ricker[,1:20],mode="bars",legend=TRUE)
tsplot(out.ricker[,1:50],mode="pcoa")
}
