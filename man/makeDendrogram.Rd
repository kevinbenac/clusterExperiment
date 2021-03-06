% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/makeDendrogram.R
\docType{methods}
\name{makeDendrogram}
\alias{makeDendrogram}
\alias{makeDendrogram,ClusterExperiment-method}
\alias{makeDendrogram,dist-method}
\alias{makeDendrogram,matrix-method}
\title{Make hierarchy of set of clusters}
\usage{
\S4method{makeDendrogram}{ClusterExperiment}(x,
  whichCluster = "primaryCluster", reduceMethod = "mad",
  nDims = defaultNDims(x, reduceMethod), ignoreUnassignedVar = TRUE,
  unassignedSamples = c("outgroup", "cluster"), ...)

\S4method{makeDendrogram}{dist}(x, cluster, unassignedSamples = c("outgroup",
  "cluster", "remove"), ...)

\S4method{makeDendrogram}{matrix}(x, cluster,
  unassignedSamples = c("outgroup", "cluster", "remove"), ...)
}
\arguments{
\item{x}{data to define the medoids from. Matrix and 
\code{\link{ClusterExperiment}} supported.}

\item{whichCluster}{an integer index or character string that identifies 
which cluster should be used to make the dendrogram. Default is 
primaryCluster.}

\item{reduceMethod}{character A character identifying what type of 
dimensionality reduction to perform before clustering. Can be either a
value stored in either of reducedDims or filterStats slot or a built-in
diminsionality reduction/filtering. The option "coCluster" will use the
co-Clustering matrix stored}

\item{nDims}{The number of dimensions to keep from \code{reduceMethod}. If
missing see details for default values. in the 'coClustering' slot of the
\code{ClusterExperiment} object.}

\item{ignoreUnassignedVar}{logical. Whether filtering statistics should
ignore the unassigned samples within the clustering. Only relevant if
'reduceMethod' matches one of built-in filtering statistics in
\code{\link{listBuiltInFilterStats}()}. In which case the clustering identified
in \code{whichCluster} is passed to \code{makeFilterStats}. See
\code{\link{makeFilterStats}}  for more details.}

\item{unassignedSamples}{how to handle unassigned samples("-1") ; only 
relevant for sample clustering. See details.}

\item{...}{for makeDendrogram, if signature \code{matrix}, arguments passed 
to hclust; if signature \code{ClusterExperiment} passed to the method for 
signature \code{matrix}. For plotDendrogram, passed to 
\code{\link{plot.dendrogram}}.}

\item{cluster}{A numeric vector with cluster assignments. If x is a 
ClusterExperiment object, cluster is automatically the primaryCluster(x). 
``-1'' indicates the sample was not assigned to a cluster.}
}
\value{
If x is a matrix, a list with two dendrograms, one in which the 
  leaves are clusters and one in which the leaves are samples. If x is a 
  ClusterExperiment object, the dendrograms are saved in the appropriate
  slots.
}
\description{
Makes a dendrogram of a set of clusters based on hclust on the 
  medoids of the cluster.
}
\details{
The function returns two dendrograms (as a list if x is a matrix or 
  in the appropriate slots if x is ClusterExperiment). The cluster dendrogram
  is created by applying \code{\link{hclust}} to the medoids of each cluster.
  In the sample dendrogram the clusters are again clustered, but now the 
  samples are also part of the resulting dendrogram. This is done by giving 
  each sample the value of the medoid of its cluster.

The argument \code{unassignedSamples} governs what is done with 
  unassigned samples (defined by a -1 cluster value). If
  unassigned=="cluster", then the dendrogram is created by hclust of the
  expanded medoid data plus the original unclustered observations. If
  \code{unassignedSamples} is "outgroup", then all unassigned samples are put
  as an outgroup. If the \code{x} object is a matrix, then
  \code{unassignedSamples} can also be "remove", to indicate that samples
  with "-1" should be discarded. This is not a permitted option, however,
  when \code{x} is a \code{ClusterExperiment} object, because it would return
  a dendrogram with less samples than \code{NCOL(x)}, which is not permitted
  for the \code{@dendro_samples} slot.

If any merge information is stored in the input object, it will be 
  erased by a call to mergeDendrogram.

If \code{nDims} is missing, it will be given a default value
  depending on the value of \code{reduceMethod}. If \code{reduceMethod} is set to a
  filtering statistic, \code{nDims} is arbitrarily set to 500. If
  \code{reduceMethod} matches a dimensionality reduction value saved in
  \code{x}, then the number of columns of this matrix. If not, and
  \code{reduceMethod} matches a value of \code{listBuiltInReducedDims()}, then
  arbirarily set to 50.
}
\examples{
data(simData)

#create a clustering, for 8 clusters (truth was 3)
cl <- clusterSingle(simData, subsample=FALSE,
sequential=FALSE, mainClusterArgs=list(clusterFunction="pam", clusterArgs=list(k=8)))

#create dendrogram of clusters:
hcl <- makeDendrogram(cl)
plotDendrogram(hcl)
plotDendrogram(hcl, leafType="samples",plotType="colorblock")

}
\seealso{
makeFilterStats, makeReducedDims
}
