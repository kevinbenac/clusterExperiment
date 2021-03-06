context("Constructor")



test_that("saved rsecFluidigm is still valid object", {
	data(rsecFluidigm)
	expect_true(validObject(rsecFluidigm))
		  })

		  
test_that("`ClusterExperiment` constructor works with matrix and SummarizedExperiments and SingleCellExperiment", {
            expect_error(ClusterExperiment(mat), "is missing, with no default")
			expect_error(ClusterExperiment(mat,as.numeric(numLabels), transformation=log), info="Error checking transFun")
            expect_error(ClusterExperiment(mat, numLabels[1:2]),
                         "must be a matrix of rows equal")
            expect_error(ClusterExperiment(as.data.frame(mat), numLabels),
                         "unable to find an inherited method for function")
            #test character input
            expect_silent(ccChar<-ClusterExperiment(mat, chLabels))
            expect_is(primaryCluster(ccChar),"numeric")
            expect_is(primaryClusterNamed(ccChar),"character")
            expect_equal(sort(unique(primaryClusterNamed(ccChar))),sort(unique(chLabels)))

            #test factor input
            expect_silent(ClusterExperiment(mat, numLabels))

            expect_is(cc, "ClusterExperiment")
            expect_is(cc, "SummarizedExperiment")

            expect_equal(nSamples(cc),ncol(mat))
            expect_equal(nFeatures(cc),nrow(mat))
            expect_equal(nClusterings(cc),2)
            expect_equal(NCOL(clusterMatrix(ccSE)), NCOL(labMat))
            
            expect_equal(colData(ccSE),colData(se)) 
            expect_equal(rownames(ccSE),rownames(se)) 
            expect_equal(colnames(ccSE),colnames(se)) 
            expect_equal(metadata(ccSE),metadata(se)) 
            expect_equal(rowData(ccSE),rowData(se)) 
            
            expect_output(show(ccSE))
			
			expect_silent(ccSCE<-ClusterExperiment(sce,as.numeric(numLabels)))
			###Need to add things specific to sce, but first need to build a sce object with new things.
			
})

test_that("whichClusters works with clusterMatrix",{
	 expect_silent(x<-dim(clusterMatrix(ceSim)))
	 expect_equal(dim(clusterMatrix(ceSim,whichClusters="all")),x)
	 expect_equal(ncol(clusterMatrix(ceSim,whichClusters="workflow")),12)
	 expect_equal(ncol(clusterMatrix(ceSim,whichClusters=1:3)),3)
	 expect_equal(ncol(clusterMatrix(ceSim,whichClusters="dendro")),0)
})
 
test_that("adding clusters work as promised",{
  ##########
  #addClusterings
  expect_silent(c1 <- addClusterings(ccSE, rep(c(-1, 1, 2), each=5),clusterTypes="newUser"))
  ###Check retain SE info
  expect_equal(colData(c1),colData(se)) 
  expect_equal(rownames(c1),rownames(se)) 
  expect_equal(colnames(c1),colnames(se)) 
  expect_equal(metadata(c1),metadata(se)) 
  expect_equal(rowData(c1),rowData(se)) 
  #Other checks
  expect_equal(NCOL(clusterMatrix(c1)), nClusterings(ccSE)+1)
  expect_equal(unname(clusterTypes(c1)), unname(c(clusterTypes(ccSE),"newUser")))
  expect_equal(length(clusteringInfo(c1)), nClusterings(ccSE)+1)
  expect_equal(primaryCluster(c1), primaryCluster(ccSE))
  primaryClusterIndex(c1) <- 3
  expect_false(all(primaryCluster(c1)==primaryCluster(ccSE)))
  
  ####check adding a ClusterExperiment to existing CE
  expect_error(addClusterings(ccSE,smSimCE),"Cannot merge clusters from different data") #assays don't match
  expect_silent(c3<-addClusterings(ccSE,ccSE))
  expect_equal(NCOL(clusterMatrix(c3)), nClusterings(ccSE)*2)
  expect_equal(length(clusterTypes(c3)), nClusterings(ccSE)*2)
  expect_equal(length(clusteringInfo(c3)), nClusterings(ccSE)*2)
  expect_equal(primaryCluster(c3), primaryCluster(ccSE))
  ###Check retain SE info
  expect_equal(colData(c3),colData(se)) 
  expect_equal(rownames(c3),rownames(se)) 
  expect_equal(colnames(c3),colnames(se)) 
  expect_equal(metadata(c3),metadata(se)) 
  expect_equal(rowData(c3),rowData(se)) 
  #Other checks after adding CE object  
  expect_error(clusterLabels(c3)[1:2]<-c("User","User"),"cannot have duplicated clusterLabels")
  clusterLabels(c3)[1:2]<-c("User1","User2")
  clusterLabels(c3)[1]<-"User4"
  expect_error(clusterLabels(c3)[1]<-"User2","cannot have duplicated clusterLabels")
  expect_equal(length(clusterLabels(c3)),nClusterings(ccSE)*2)
  
  ###check adding matrix of clusters
  expect_silent(c4<-addClusterings(ccSE,clusterMatrix(ccSE),clusterTypes="New"))
  expect_silent(newLeng<-2*nClusterings(ccSE))
  expect_equal(NCOL(clusterMatrix(c4)), newLeng)
  expect_equal(length(clusterTypes(c4)), newLeng)
  expect_equal(length(clusteringInfo(c4)), newLeng)
  expect_equal(primaryCluster(c4), primaryCluster(ccSE))
  ###Check retain SE info
  expect_equal(colData(c4),colData(se)) 
  expect_equal(rownames(c4),rownames(se)) 
  expect_equal(colnames(c4),colnames(se)) 
  expect_equal(metadata(c4),metadata(se)) 
  expect_equal(rowData(c4),rowData(se)) 
})  

test_that("removing clusters work as promised",{
  ##########
  #check removeClusterings
  
  #single cluster
  expect_silent(c4<-addClusterings(ccSE,clusterMatrix(ccSE),clusterTypes="New"))
  expect_silent(c5<-removeClusterings(c4,1))
  expect_equal(NCOL(clusterMatrix(c5)), nClusterings(c4)-1)
  expect_equal(length(clusterTypes(c5)), nClusterings(c4)-1)
  expect_equal(length(clusteringInfo(c5)), nClusterings(c4)-1)
  expect_equal(primaryCluster(c4), primaryCluster(removeClusterings(c4,2)))
  ###Check retain SE info 
  expect_equal(colData(c5),colData(se)) 
  expect_equal(rownames(c5),rownames(se)) 
  expect_equal(colnames(c5),colnames(se)) 
  expect_equal(metadata(c5),metadata(se)) 
  expect_equal(rowData(c5),rowData(se)) 
  
  #vector clusters
  expect_silent(c6<-removeClusterings(c4,c(1,3)))
  expect_equal(NCOL(clusterMatrix(c6)), nClusterings(c4)-2)
  expect_equal(length(clusterTypes(c6)), nClusterings(c4)-2)
  expect_equal(length(clusteringInfo(c6)), nClusterings(c4)-2)
  ###Check retain SE info 
  expect_equal(colData(c6),colData(se)) 
  expect_equal(rownames(c6),rownames(se)) 
  expect_equal(colnames(c6),colnames(se)) 
  expect_equal(metadata(c6),metadata(se)) 
  expect_equal(rowData(c6),rowData(se)) 
  
  expect_error(removeClusterings(c4,c(1,nClusterings(c4)+1)),"invalid indices")
  
  expect_silent(c7<-removeClusterings(c4,"User")) #two have "user" label
  expect_equal(NCOL(clusterMatrix(c7)), nClusterings(c4)-2)
  expect_equal(length(clusterTypes(c7)), nClusterings(c4)-2)
  expect_equal(length(clusteringInfo(c7)), nClusterings(c4)-2)
  
  ##########
  ###Check removing a cluster assignment
  ########## 
  c1<-ccSE
  cL<-clusterLegend(c1)
  ind<-primaryClusterIndex(c1)
  cL[[ind]][,"name"]<-letters[1:nrow(cL[[ind]])]
  clusterLegend(c1)<-cL
  rmCl<-c(2,3)
  rmNms<-cL[[ind]][cL[[ind]][,"clusterIds"] %in% as.character(rmCl),"name"]
  x<-removeClusters(c1,whichCluster="primary",clustersToRemove=rmCl)
  expect_equal(sum(primaryCluster(x)==-1), sum(primaryCluster(c1) %in% c(-1,2,3)))
  newnms<-clusterLegend(x)[[primaryClusterIndex(x)]][,"name"]
  old<-clusterLegend(x)[[ind]]
  oldnms<-old[!old[,"name"] %in% rmNms,"name"]
  expect_equal(oldnms,newnms)
  
   x<-removeClusters(c1,whichCluster="primary",clustersToRemove=rmNms)
   expect_equal(sum(primaryCluster(x)==-1), sum(primaryCluster(c1) %in% c(-1,2,3)))
   newnms<-clusterLegend(x)[[primaryClusterIndex(x)]][,"name"]
   old<-clusterLegend(x)[[ind]]
   oldnms<-old[!old[,"name"] %in% rmNms,"name"]
   expect_equal(oldnms,newnms)
 
  
  
  ##########
  #check removing unclustered samples
  ##########
  #no -1 in primary cluster
  matTemp<-abs(labMat)
  expect_silent(ccTemp<-ClusterExperiment(mat,matTemp,transformation=function(x){x}))
  expect_equal(ccTemp, removeUnclustered(ccTemp)) 
  
###This is giving me error with new SCE class, but once I put in browser to check it out, works!!! Some kind of unloadNamespace problem?
  #-1 in primary cluster
whUn<-which(primaryCluster(ccSE) <0)
  expect_silent(ccR<-removeUnclustered(ccSE))
  expect_equal(NCOL(ccR), NCOL(ccSE)-length(whUn))

  ###Check retain SE info
  expect_equal(colData(ccR),colData(se[,-whUn]) )
  expect_equal(rownames(ccR),rownames(se)) 
  expect_equal(colnames(ccR),colnames(se[,-whUn])) 
  expect_equal(metadata(ccR),metadata(se)) 
  expect_equal(rowData(ccR),rowData(se)) 
  
})

test_that("subsetting works as promised",{

  expect_equal(clusterMatrix(cc[1:2,1]),clusterMatrix(cc)[1,,drop=FALSE]) 
  
  expect_equal(clusterMatrix(cc[1:2,-c(1, 2)]),clusterMatrix(cc)[-c(1, 2),]) 
  
  #test subsetting of genes
  expect_equal(clusterMatrix(cc[1:2,c(1, 2)]),clusterMatrix(cc)[c(1, 2),]) 
  expect_equal(dim(cc[1:2,c(1, 2)]),c(2,2))
  
  #test subsetting of samples
  expect_equal(clusterMatrix(cc[,c(1, 2)]),clusterMatrix(cc)[c(1, 2),])
  logVec<-rep(FALSE,length=nSamples(cc))
  logVec[1:2]<-TRUE
  expect_equal(clusterMatrix(cc[,logVec]),clusterMatrix(cc)[logVec,]) 
  expect_equal(clusterMatrix(cc[,c("Sample 1" , "Sample 2")]),clusterMatrix(cc)[c(1, 2),]) 

  
  
  ##########
  #checks SE info (which isn't biggest place needs unit tests since uses callNextMethod() so should work)
  #therefore currently just really checks no errors. 
  expect_silent(x1<-ccSE[,5:8])
  ###Check retain SE info
  expect_equal(colData(x1),colData(se[,5:8]) )
  expect_equal(rownames(x1),rownames(se[,5:8])) 
  expect_equal(colnames(x1),colnames(se[,5:8])) 
  expect_equal(metadata(x1),metadata(se[,5:8])) 
  expect_equal(rowData(x1),rowData(se[,5:8])) 
  
  expect_silent(x2<-ccSE[1:2,])
  ###Check retain SE info
  expect_equal(colData(x2),colData(se[1:2,]) )
  expect_equal(rownames(x2),rownames(se[1:2,])) 
  expect_equal(colnames(x2),colnames(se[1:2,])) 
  expect_equal(metadata(x2),metadata(se[1:2,])) 
  expect_equal(rowData(x2),rowData(se[1:2,])) 
  
  expect_silent(x3<-ccSE[,3])
  ###Check retain SE info
  expect_equal(colData(x3),colData(se[,3]) )
  expect_equal(rownames(x3),rownames(se[,3])) 
  expect_equal(colnames(x3),colnames(se[,3])) 
  expect_equal(metadata(x3),metadata(se[,3])) 
  expect_equal(rowData(x3),rowData(se[,3])) 
  
  expect_silent(x4<-ccSE[3,])
  ###Check retain SE info
  expect_equal(colData(x4),colData(se[3,]) )
  expect_equal(rownames(x4),rownames(se[3,])) 
  expect_equal(colnames(x4),colnames(se[3,])) 
  expect_equal(metadata(x4),metadata(se[3,])) 
  expect_equal(rowData(x4),rowData(se[3,])) 
  
  
  expect_equal(clusterExperiment:::filterStats(sceSimData[1:10,]),head(clusterExperiment:::filterStats(sceSimData),10))
})

test_that("check clusterLegend manipulations work as promised", {
    x<-clusterLegend(cc)
    expect_silent(clusterLegend(cc)<-x)
    expect_silent(c4<-addClusterings(ccSE,clusterMatrix(ccSE),clusterTypes="New",clusterLabels=c("new1","new2"),clusterLegend=clusterLegend(ccSE)))
    expect_silent(clusterLegend(c4)[1:2]<-x[1:2])
    expect_silent(clusterLegend(c4)[[1]]<-x[[1]])
#add wrong dimensions:
    expect_error(clusterLegend(c4)[3]<-list(x[[1]][1:2,]),"each element of `clusterLegend` must be matrix with")
    expect_error(clusterLegend(c4)[[3]]<-x[[1]][1:2,],"must be matrix with")
	
    ##########
	#check adding clusterLegend directly to constructor
    ##########
	newcc<-ClusterExperiment(as(cc,"SingleCellExperiment"),clusters=clusterMatrix(cc),clusterLegend=clusterLegend(cc))
	expect_equal(cc,newcc)

	newCL<-clusterLegend(cc)
	newCL[[1]][,"name"]<-letters[1:nrow(newCL[[1]])]
	cc1<-cc
	clusterLegend(cc1)<-newCL
	newClusters<-convertClusterLegend(cc1,output="matrixNames")
	newCL[[1]][,"clusterIds"]<-newCL[[1]][,"name"]
	newCL[[1]][,"name"]<-LETTERS[1:nrow(newCL[[1]])]
  newcc<-ClusterExperiment(as(cc,"SingleCellExperiment"),clusters=newClusters,clusterLegend=newCL) 
  expect_equal(clusterLegend(newcc)[[1]][,c("name","color")], newCL[[1]][,c("name","color")])
	     
})

test_that("accessing transformed data works as promised",{
  expect_is(transformation(ccSE),"function")
  expect_equal(transformData(cc), transformation(cc)(assay(cc)))
})

test_that("workflow functions work",
          {
            ##########
            #check workflow stuff
            expect_silent(ppC<-addClusterings(cc,cbind(rep(c(-1, 1,2), each=5),rep(c(2, 1,3), each=5)),clusterTypes=c("clusterMany","mergeClusters")))
            expect_equal(dim(workflowClusters(ppC)),c(nSamples(cc),2))
            
            expect_silent(ppC<-addClusterings(cc,cbind(rep(c(-1, 1,2), each=5)),clusterTypes=c("clusterMany")))
            expect_equal(dim(workflowClusters(ppC)),c(nSamples(cc),1))
            
            expect_silent(ppC<-addClusterings(cc,cbind(rep(c(-1, 1,2), each=5),rep(c(2, 3,1), each=5)),clusterTypes=c("clusterMany","mergeClusters.1")))
            expect_equal(dim(workflowClusters(ppC)),c(nSamples(cc),1))
            expect_equal(dim(workflowClusters(ppC,iteration=NA)),c(nSamples(cc),2))
            expect_null(workflowClusters(cc,iteration=NA))
          
  expect_message(ceNew<-combineMany(ceSim,proportion=0.7))
  expect_message(ceNew<-combineMany(ceNew,proportion=0.3,clusterLabel="combineMany,v2"))
  expect_equal(clusterLabels(ceNew)[1:2],c("combineMany,v2","combineMany.1"))
  expect_equal(clusterTypes(ceNew)[1:2],c("combineMany","combineMany.1"))
  expect_silent(ceNew2<-setToCurrent(ceNew,whichCluster="combineMany.1"))
  expect_equal(clusterLabels(ceNew2)[1:2],c("combineMany,v2","combineMany"))
  expect_equal(clusterTypes(ceNew2)[1:2],c("combineMany.2","combineMany"))
  expect_silent(ceNew3<-setToCurrent(ceNew2,whichCluster="combineMany.2"))
  expect_equal(clusterLabels(ceNew3)[1:2],c("combineMany,v2","combineMany.3"))
  expect_equal(clusterTypes(ceNew3)[1:2],c("combineMany","combineMany.3"))

  expect_silent(ceNew4<-setToFinal(ceNew,whichCluster="combineMany,v2",clusterLabel="Final Version"))
  expect_equal(primaryClusterIndex(ceNew4),1)
  expect_equal(clusterLabels(ceNew4)[primaryClusterIndex(ceNew4)],"Final Version")
  expect_equal(clusterTypes(ceNew4)[primaryClusterIndex(ceNew4)],"final")
  
  expect_silent(ceNew5<-setToFinal(ceNew,whichCluster="combineMany.1",clusterLabel="Final Version"))
  expect_equal(primaryClusterIndex(ceNew5),2)
  expect_equal(clusterLabels(ceNew5)[primaryClusterIndex(ceNew5)],"Final Version")
  expect_equal(clusterTypes(ceNew5)[primaryClusterIndex(ceNew5)],"final")
          })