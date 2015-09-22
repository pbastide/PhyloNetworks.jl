# test to see if the likelihood is correctly calculated
# and if the networks are correctly estimated
# Claudia August 2015

# -------------------5taxon tree------------------

#include("../src/types.jl")
#include("../src/functions.jl")

#df = readtable("Tree_output.txt")
df=DataFrame(t1=["6","6","10","6","6"],t2=["7","7","7","10","7"],t3=["4","10","4","4","4"],t4=["8","8","8","8","10"],CF1234=[0.2729102510259939, 0.3967750546426937, 0.30161247267865315, 0.24693940689390592, 0.2729102510259939], CF1324=[0.45417949794801216, 0.30161247267865315, 0.30161247267865315, 0.5061211862121882, 0.45417949794801216],CF1423=[0.2729102510259939, 0.30161247267865315, 0.3967750546426937, 0.24693940689390592, 0.2729102510259939])
d = readTableCF(df)

# starting tree:
tree = "((6,4),(7,8),10);"
currT = readTopologyUpdate(tree);
printEdges(currT)

extractQuartet!(currT,d)
calculateExpCFAll!(d)
lik = logPseudoLik(d)

approxEq(lik,193.7812623319291) || error("not correct likelihood calculated with tree")

estTree = snaq(currT,d,hmax=0,returnNet=true,seed=5454);

approxEq(estTree.loglik,0.0) || error("not correct tree estimated")

# ------------------5taxon network 1 hybridization: Case H-----------------
# starting topology: Case G
tree = "((((6:0.1,4:1.5)1:0.2,(7)11#H1)5:0.1,(11#H1,8)),10:0.1);" # Case G
currT = readTopologyUpdate(tree);
printEdges(currT)

# real network: Case H
#df = readtable("CaseH_output.txt")
df=DataFrame(t1=["6","6","10","6","6"],t2=["7","7","7","10","7"],t3=["4","10","4","4","4"],t4=["8","8","8","8","10"],CF1234=[0.13002257237728915, 0.36936019721747243, 0.34692592933269173, 0.12051951084152591, 0.11095702789935982], CF1324=[0.7399548552454217, 0.28371387344983595, 0.28371387344983595, 0.7589609783169482, 0.7780859442012804],CF1423=[0.13002257237728915, 0.34692592933269173, 0.36936019721747243, 0.12051951084152591, 0.11095702789935982])
d = readTableCF(df)

extractQuartet!(currT,d)
calculateExpCFAll!(d)
lik = logPseudoLik(d)

approxEq(lik,50.17161079450669) || error("not correct likelihood calculated with tree")

estNet = snaq(currT,d,hmax=1,runs=1,returnNet=true,seed=5454);

approxEq(estNet.loglik,0.0021628920163591636)  || error("not correct net estimated")

