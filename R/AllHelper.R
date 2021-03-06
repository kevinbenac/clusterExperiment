#' Helper methods for the ClusterExperiment class
#'
#' This is a collection of helper methods for the ClusterExperiment class.
#' @name ClusterExperiment-methods
#' @aliases ClusterExperiment-methods [,ClusterExperiment,ANY,ANY,ANY-method [,ClusterExperiment,ANY,character,ANY-method
#' @details Note that when subsetting the data, the dendrogram information and
#' the co-clustering matrix are lost.
#' @export
#' @param ...,i,j,drop Forwarded to the
#'   \code{\link{SingleCellExperiment}} method.
#' @param value The value to be substituted in the corresponding slot. See the
#'   slot descriptions in \code{\link{ClusterExperiment}} for details on what
#'   objects may be passed to these functions.
setMethod(
  f = "[",
  signature = c("ClusterExperiment", "ANY", "character"),
  definition = function(x, i, j, ..., drop=TRUE) {
    j<-match(j, colnames(x))
    callGeneric()
    
  }
)
#' @rdname ClusterExperiment-methods
#' @export
setMethod(
  f = "[",
  signature = c("ClusterExperiment", "ANY", "logical"),
  definition = function(x, i, j, ..., drop=TRUE) {
    j<-which(j)
    callGeneric()
  }
)
#' @rdname ClusterExperiment-methods
#' @export
setMethod(
  f = "[",
  signature = c("ClusterExperiment", "ANY", "numeric"),
  definition = function(x, i, j, ..., drop=TRUE) {
    # #out <- callNextMethod() #doesn't work once I added the logical and character choices.
    # out<-selectMethod("[",c("SingleCellExperiment","ANY","numeric"))(x,i,j) #have to explicitly give the inherintence... not great.
	###Note: Could fix subsetting, so that if subset on genes, but same set of samples, doesn't do any of this...
	#Following Martin Morgan advice, do "new" rather than @<- to create changed object
    #need to subset cluster matrix and convert to consecutive integer valued clusters:
    subMat<-as.matrix(x@clusterMatrix[j, ,drop=FALSE])
	nms<-colnames(subMat)
	newMat<-.makeIntegerClusters(subMat) #need separate so can compare to fix up clusterLegend
    colnames(newMat)<-nms
    ##Fix clusterLegend slot, in case now lost a level and to match new integer values
    newClLegend<-lapply(1:NCOL(newMat),function(ii){
        colMat<-x@clusterLegend[[ii]]
        newCl<-newMat[,ii]
        cl<-subMat[,ii]
        #remove (possible) levels lost
        whRm<-which(!colMat[,"clusterIds"] %in% as.character(cl))
        if(length(whRm)>0){
            colMat<-colMat[-whRm,,drop=FALSE]
        }
        #convert
        oldNew<-unique(cbind(old=cl,new=newCl))
        if(nrow(oldNew)!=nrow(colMat)) stop("error in converting colorLegend")
        m<-match(colMat[,"clusterIds"],oldNew[,"old"])
        colMat[,"clusterIds"]<-oldNew[m,"new"]
        return(colMat)
    })
	#fix order of samples so same
	newOrder<-rank(x@orderSamples[j])
	#
    out<- ClusterExperiment(
object=as(selectMethod("[",c("SingleCellExperiment","ANY","numeric"))(x,i,j),"SingleCellExperiment"),#have to explicitly give the inherintence... not great.
             clusters = newMat,
               transformation=x@transformation,
               primaryIndex = x@primaryIndex,
               clusterTypes = x@clusterTypes,
               clusterInfo=x@clusterInfo,
               orderSamples=newOrder,
			   clusterLegend=newClLegend,
			   checkTransformAndAssay=FALSE
    )
#	clusterLegend(out)<-newClLegend
    return(out)
  }
)

## show
#' @rdname ClusterExperiment-methods
#' @export
setMethod(
  f = "show",
  signature = "ClusterExperiment",
  definition = function(object) {
    cat("class:", class(object), "\n")
    cat("dim:", dim(object), "\n")
	cat("reducedDimNames:",if(anyValidReducedDims(object)) reducedDimNames(object) else "no reduced dims stored","\n")
	cat("filterStats:",if(anyValidFilterStats(object)) filterNames(object) else "no valid filtering stats stored","\n")
    cat("-----------\n")
    cat("Primary cluster type:", clusterTypes(object)[primaryClusterIndex(object)],"\n")
    cat("Primary cluster label:", clusterLabels(object)[primaryClusterIndex(object)],"\n")
    cat("Table of clusters (of primary clustering):")
    print(table(primaryClusterNamed(object)))
    cat("Total number of clusterings:", NCOL(clusterMatrix(object)),"\n")
    if(!is.na(dendroClusterIndex(object)) ) cat("Dendrogram run on '",clusterLabels(object)[dendroClusterIndex(object)],"' (cluster index: ", dendroClusterIndex(object),")\n",sep="") else cat("No dendrogram present\n")
    cat("-----------\n")
    cat("Workflow progress:\n")
    typeTab<-names(table(clusterTypes(object)))
    cat("clusterMany run?",if("clusterMany" %in% typeTab) "Yes" else "No","\n")
    cat("combineMany run?",if("combineMany" %in% typeTab) "Yes" else "No","\n")
    cat("makeDendrogram run?",if(!is.null(object@dendro_samples) & !is.null(object@dendro_clusters) ) "Yes" else "No","\n")
    cat("mergeClusters run?",if("mergeClusters" %in% typeTab) "Yes" else "No","\n")
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{clusterMatrixNamed} returns a matrix with cluster labels.
#' @export
#' @aliases clusterMatrixNamed
#' @param x,object a ClusterExperiment object.
setMethod(
  f = "clusterMatrixNamed",
  signature = "ClusterExperiment",
  definition = function(x) {
    clMat<-clusterMatrix(x)
    out<-do.call("cbind",lapply(1:ncol(clMat),function(ii){
      cl<-clMat[,ii]
      leg<-clusterLegend(x)[[ii]]
      leg[,"name"][match(cl,leg[,"clusterIds"])]
    }))
    colnames(out)<-colnames(clMat)
    rownames(out)<-NULL
    return(out)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{primaryClusterNamed} returns the primary cluster (using cluster
#' labels).
#' @export
#' @aliases primaryClusterNamed
setMethod(
  f = "primaryClusterNamed",
  signature = "ClusterExperiment",
  definition = function(x) {
    clusterMatrixNamed(x)[,primaryClusterIndex(x)]
  })

#' @rdname ClusterExperiment-methods
#' @return \code{transformation} prints the function used to transform the data
#' prior to clustering.
#' @export
#' @aliases transformation
setMethod(
  f = "transformation",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@transformation)
  }
)

#' @rdname ClusterExperiment-methods
#' @export
#' @details Note that redefining the transformation function via
#'   \code{transformation(x)<-} will check the validity of the transformation on
#'   the data assay. If the assay is large, this may be time consuming. Consider
#'   using a call to ClusterExperiment, which has the option as to whether to
#'   check the validity of the transformation.
#' @aliases transformation<-
setReplaceMethod(
  f = "transformation",
  signature = signature("ClusterExperiment", "function"),
  definition = function(object, value) {
	checkValidity=TRUE
    object@transformation <- value
    if(checkValidity){
		ch<-.checkTransform(object)
    	if(ch) return(object) else stop(ch)
	}
	else return(object)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{nClusterings} returns the number of clusterings (i.e., ncol of
#' clusterMatrix).
#' @export
#' @aliases nClusterings
setMethod(
  f = "nClusterings",
  signature = "ClusterExperiment",
  definition = function(x){
    return(NCOL(clusterMatrix(x)))
  }
)


#' @rdname ClusterExperiment-methods
#' @return \code{nClusters} returns the number of clusters per clustering
#' @param ignoreUnassigned logical. If true, ignore the clusters with -1 or -2 assignments in calculating the number of clusters per clustering. 
#' @export
#' @aliases nClusters
setMethod(
  f = "nClusters",
  signature = "ClusterExperiment",
  definition = function(x,ignoreUnassigned=TRUE){
	  if(ignoreUnassigned){
		  return(apply(clusterMatrix(x),2,function(x){length(unique(x[x>0]))}))
	  }
	  else return(apply(clusterMatrix(x),2,function(x){length(unique(x))}))
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{nFeatures} returns the number of features (same as `nrow`).
#' @aliases nFeatures
#' @export
setMethod(
  f = "nFeatures",
  signature =  "ClusterExperiment",
  definition = function(x){
    return(NROW(assay(x)))
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{nSamples} returns the number of samples (same as `ncol`).
#' @aliases nSamples
#' @export
setMethod(
  f = "nSamples",
  signature = "ClusterExperiment",
  definition = function(x){
    return(NCOL(assay(x)))
  }
)

#' @rdname ClusterExperiment-methods
#' @param whichClusters optional argument that can be either numeric or
#'   character value. If numeric, gives the indices of the \code{clusterMatrix}
#'   to return; this can also be used to defined an ordering for the
#'   clusterings. \code{whichClusters} can be a character value identifying the 
#'   \code{clusterTypes} to be used, or if not matching \code{clusterTypes} then
#'   \code{clusterLabels}; alternatively \code{whichClusters} can be either 
#'   'all' or 'workflow' to indicate choosing all clusters or choosing all 
#'   \code{\link{workflowClusters}}. If missing, the entire matrix of all
#'   clusterings is returned.
#' @return \code{clusterMatrix} returns the matrix with all the clusterings.
#' @export
#' @aliases clusterMatrix
setMethod(
  f = "clusterMatrix",
  signature = c("ClusterExperiment","missing"),
  definition = function(x,whichClusters) {
	  wh<-1:ncol(x@clusterMatrix)
   return(clusterMatrix(x,whichClusters=wh))
  }
)
#' @rdname ClusterExperiment-methods
#' @return \code{clusterMatrix} returns the matrix with all the clusterings.
#' @export
#' @aliases clusterMatrix
setMethod(
  f = "clusterMatrix",
  signature = c("ClusterExperiment","numeric"),
  definition = function(x,whichClusters) {
	  mat<-x@clusterMatrix[,whichClusters,drop=FALSE]
	  rownames(mat)<-colnames(x)
    return(mat)
  }
)
#' @rdname ClusterExperiment-methods
#' @return \code{clusterMatrix} returns the matrix with all the clusterings.
#' @export
#' @aliases clusterMatrix
setMethod(
  f = "clusterMatrix",
  signature = c("ClusterExperiment","character"),
  definition = function(x,whichClusters) {
	  wh<-.TypeIntoIndices(x,whClusters=whichClusters)
	  return(clusterMatrix(x,whichClusters=wh))
  }
)


#' @rdname ClusterExperiment-methods
#' @return \code{primaryCluster} returns the primary clustering (as numeric).
#' @export
#' @aliases primaryCluster
setMethod(
  f = "primaryCluster",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@clusterMatrix[,primaryClusterIndex(x)])
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{primaryClusterIndex} returns/sets the primary clustering index
#' (i.e., which column of clusterMatrix corresponds to the primary clustering).
#' @export
#' @aliases primaryClusterIndex
setMethod(
  f = "primaryClusterIndex",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@primaryIndex)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{dendroClusterIndex} returns/sets the clustering index 
#' of the clusters used to create dendrogram
#' (i.e., which column of clusterMatrix corresponds to the clustering).
#' @export
#' @aliases dendroClusterIndex
setMethod(
  f = "dendroClusterIndex",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@dendro_index)
  }
)

#' @rdname ClusterExperiment-methods
#' @export
#' @aliases primaryClusterIndex<-
setReplaceMethod(
  f = "primaryClusterIndex",
  signature = signature("ClusterExperiment", "numeric"),
  definition = function(object, value) {
    object@primaryIndex <- value
    ch<-.checkPrimaryIndex(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{coClustering} returns/sets the co-clustering matrix.
#' @export
#' @aliases coClustering
setMethod(
  f = "coClustering",
  signature = "ClusterExperiment",
  definition = function(x) {
    return(x@coClustering)
  }
)

#' @rdname ClusterExperiment-methods
#' @export
#' @aliases coClustering<-
setReplaceMethod(
  f = "coClustering",
  signature = signature(object="ClusterExperiment", value="matrix"),
  definition = function(object, value) {
    object@coClustering <- value
	ch<-.checkCoClustering(object)
    if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{clusterTypes} returns/sets the clusterTypes slot.
#' @export
#' @aliases clusterTypes
setMethod(
  f = "clusterTypes",
  signature = "ClusterExperiment",
  definition = function(x) {
    out<-x@clusterTypes
    #names(out)<-clusterLabels(x)
    return(out)
  }
)

#' @rdname ClusterExperiment-methods
#' @return \code{clusteringInfo} returns the clusterInfo slot.
#' @aliases clusteringInfo
#' @export
setMethod(
  f = "clusteringInfo",
  signature = "ClusterExperiment",
  definition = function(x) {
    out<-x@clusterInfo
    names(out)<-clusterLabels(x)
    return(out)
  }
)


#' @rdname ClusterExperiment-methods
#' @return \code{clusterLabels} returns/sets the column names of the clusterMatrix slot.
#' @export
#' @aliases clusterLabels
setMethod(
  f = "clusterLabels",
  signature = signature(x = "ClusterExperiment"),
  definition = function(x){
    labels<-colnames(clusterMatrix(x))
    if(is.null(labels)) cat("No labels found for clusterings\n")
    return(labels)

  }
)
#' @export
#' @rdname ClusterExperiment-methods
#' @aliases clusterLabels<-
setReplaceMethod( f = "clusterLabels",
  signature = signature(object="ClusterExperiment", value="character"),
  definition = function(object, value) {
    if(length(value)!=NCOL(clusterMatrix(object))) stop("value must be a vector of length equal to NCOL(clusterMatrix(object)):",NCOL(clusterMatrix(object)))
    colnames(object@clusterMatrix) <- value
    ch<-.checkClusterLabels(object)
	if(is.logical(ch) && ch) return(object) else stop(ch)
  }
)
#' @rdname ClusterExperiment-methods
#' @return \code{clusterLegend} returns/sets the clusterLegend slot.
#' @export
#' @aliases clusterLegend
setMethod(
    f = "clusterLegend",
    signature = "ClusterExperiment",
    definition = function(x) {
      out<-x@clusterLegend
      names(out)<-clusterLabels(x)
      return(out)
    }
)
#' @rdname ClusterExperiment-methods
#' @export
#' @aliases clusterLegend<-
setReplaceMethod( f = "clusterLegend",
    signature = signature(object="ClusterExperiment", value="list"),
    definition = function(object, value) {
        object@clusterLegend<-unname(value)
        ch<-.checkClusterLegend(object)
		if(is.logical(ch) && ch) return(object) else stop(ch)
    }
)

#' @rdname ClusterExperiment-methods
#' @return \code{orderSamples} returns/sets the orderSamples slot.
#' @export
#' @aliases orderSamples
setMethod(
    f = "orderSamples",
    signature = "ClusterExperiment",
    definition = function(x) {
        return(x@orderSamples)
    }
)
#' @rdname ClusterExperiment-methods
#' @export
#' @aliases orderSamples<-
setReplaceMethod( f = "orderSamples",
    signature = signature(object="ClusterExperiment", value="numeric"),
    definition = function(object, value) {
		object@orderSamples<-value
		ch<-.checkOrderSamples(object) 
		if(is.logical(ch) && ch) return(object) else stop(ch)
        
    }
)

#' @rdname ClusterExperiment-methods
#' @export
#' @aliases clusterTypes<-
setReplaceMethod( f = "clusterTypes",
    signature = signature(object="ClusterExperiment", value="character"),
    definition = function(object,value) {
        object@clusterTypes<-value
        object<-.unnameClusterSlots(object)
        ch<-.checkClusterTypes(object)
		if(is.logical(ch) && ch) return(object) else stop(ch)
        
    }
)


#' @aliases tableClusters
#' @rdname ClusterExperiment-methods
setMethod( f = "tableClusters",
  signature = signature(x = "ClusterExperiment",whichClusters="character"),
  definition = function(x, whichClusters,...)
  {
	wh<-.TypeIntoIndices(x,whClusters=whichClusters)
	if(length(wh)==0) stop("invalid choice of 'whichClusters'")
	return(tableClusters(x,whichClusters=wh,...))

  })

#' @rdname ClusterExperiment-methods
#' @export
setMethod( f = "tableClusters",
    signature = signature(x = "ClusterExperiment",whichClusters="missing"),
    definition = function(x, whichClusters,...)
    {
      tableClusters(x,whichClusters="primaryCluster")

    })

#' @rdname ClusterExperiment-methods
#' @export
setMethod( f = "tableClusters",
  signature = signature(x = "ClusterExperiment",whichClusters="numeric"),
  definition = function(x, whichClusters,...)
  { 
	numCluster<-clusterMatrix(x)[,whichClusters]
	table(data.frame(numCluster))
})


# # Need to implement: wrapper to get a nice summary of the parameters choosen, similar to that of paramMatrix of clusterMany (and compatible with it)
# #' @rdname ClusterExperiment-class
# setMethod(
#   f= "paramValues",
#   signature = "ClusterExperiment",
#   definition=function(x,type){
#     whCC<-which(clusterTypes(x)==type)
#     if(length(wwCC)==0) stop("No clusterings of type equal to ",type,"are found")
#     if(type=="clusterMany"){
#       #recreate the paramMatrix return value
#       paramMatrix<-do.call("rbind",lapply(wwCC,function(ii){
#         data.frame(index=ii,clusteringInfo(x)[[ii]]["choicesParam"])
#       }))
#
#     }
#     else if(type=="clusterSingle"){
#
#     }
#     else{
#       return(clusteringInfo(x)[whCC])
#     }
#   }
# )
