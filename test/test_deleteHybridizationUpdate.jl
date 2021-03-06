# test to see that deleteHybridizationUpdate undoes all attributes
# prompted by Cecile finding cases when containRoot was not updated
# Claudia December 2015

if !isdefined(:individualtest) individualtest = false; end

if(individualtest)
    include("../src/types.jl")
    include("../src/functions.jl")
    const DEBUG = true
end

if isdefined(:PhyloNetworks)
    PhyloNetworks.CHECKNET || error("need CHECKNET==true in PhyloNetworks to test snaq in test_correctLik.jl")
else
    CHECKNET || error("need CHECKNET==true to test snaq in test_correctLik.jl")
end

@testset "test: delete hybridization" begin

tree = "(((((((1,2),3),4),5),(6,7)),(8,9)),10);"

#seed = 2738
seed = 56326

currT0 = readTopologyLevel1(tree);
## printEdges(currT0)
## printNodes(currT0)
## writeTopologyLevel1(currT0)
checkNet(currT0)
srand(seed);
besttree = deepcopy(currT0);

# ===== first hybridization ==========================
@testset "first hybridization" begin
success,hybrid,flag,nocycle,flag2,flag3 = addHybridizationUpdate!(besttree);
@test success
#printEdges(besttree)
#printNodes(besttree)
@test_nowarn writeTopologyLevel1(besttree)
net = deepcopy(besttree);
# test contain root
@test !net.edge[15].containRoot
@test !net.edge[19].containRoot
@test !net.edge[20].containRoot

# test inCycle
@test net.edge[12].inCycle == 11
@test net.edge[13].inCycle == 11
@test net.edge[16].inCycle == 11
@test net.edge[18].inCycle == 11
@test net.edge[19].inCycle == 11
@test net.edge[20].inCycle == 11

@test net.node[12].inCycle == 11
@test net.node[13].inCycle == 11
@test net.node[16].inCycle == 11
@test net.node[17].inCycle == 11
@test net.node[19].inCycle == 11
@test net.node[20].inCycle == 11

# test partition
@test length(net.partition) == 6
@test [n.number for n in net.partition[1].edges] == [15]
@test [n.number for n in net.partition[2].edges] == [11]
@test [n.number for n in net.partition[3].edges] == [10]
@test [n.number for n in net.partition[4].edges] == [9,7,5,3,1,2,4,6,8]
@test [n.number for n in net.partition[5].edges] == [17]
@test [n.number for n in net.partition[6].edges] == [14]
end

# ===== second hybridization ==========================
@testset "second hybridization" begin
success = false
success,hybrid,flag,nocycle,flag2,flag3 = addHybridizationUpdate!(besttree);
@test success
#printEdges(besttree)
#printNodes(besttree)
@test_nowarn writeTopologyLevel1(besttree,true)
net = deepcopy(besttree);

# test contain root
@test !net.edge[15].containRoot
@test !net.edge[19].containRoot
@test !net.edge[20].containRoot
@test !net.edge[3].containRoot
@test !net.edge[1].containRoot
@test !net.edge[2].containRoot
@test !net.edge[23].containRoot
@test !net.edge[22].containRoot

# test inCycle
@test net.edge[12].inCycle == 11
@test net.edge[13].inCycle == 11
@test net.edge[16].inCycle == 11
@test net.edge[18].inCycle == 11
@test net.edge[19].inCycle == 11
@test net.edge[20].inCycle == 11

@test net.node[12].inCycle == 11
@test net.node[13].inCycle == 11
@test net.node[16].inCycle == 11
@test net.node[17].inCycle == 11
@test net.node[19].inCycle == 11
@test net.node[20].inCycle == 11

@test net.edge[9].inCycle == 13
@test net.edge[7].inCycle == 13
@test net.edge[5].inCycle == 13
@test net.edge[22].inCycle == 13
@test net.edge[23].inCycle == 13

@test net.node[5].inCycle == 13
@test net.node[7].inCycle == 13
@test net.node[9].inCycle == 13
@test net.node[21].inCycle == 13
@test net.node[22].inCycle == 13


# test partition
@test length(net.partition) == 10
@test [n.number for n in net.partition[1].edges] == [15]
@test [n.number for n in net.partition[2].edges] == [11]
@test [n.number for n in net.partition[3].edges] == [10]
@test [n.number for n in net.partition[4].edges] == [17]
@test [n.number for n in net.partition[5].edges] == [14]
@test [n.number for n in net.partition[6].edges] == [3,1,2]
@test [n.number for n in net.partition[7].edges] == [21]
@test [n.number for n in net.partition[8].edges] == [8]
@test [n.number for n in net.partition[9].edges] == [6]
@test [n.number for n in net.partition[10].edges] == [4]
end

## # ===== identify containRoot for net.node[21]
## net0=deepcopy(net);
## hybrid = net.node[21];
## hybrid.isBadDiamondI
## nocycle, edgesInCycle, nodesInCycle = identifyInCycle(net,hybrid);
## [n.number for n in edgesInCycle] == [23,9,7,5,22] || error("wrong identified cycle")
## [n.number for n in nodesInCycle] == [13,14,-4,-5,-6] || error("wrong identified cycle")
## edgesRoot = identifyContainRoot(net,hybrid);
## [n.number for n in edgesRoot] == [3,1,2] || error("wrong identified contain root")
## [e.containRoot for e in edgesRoot] == [false,false,false] || error("edges root should be false contain root")
## edges = hybridEdges(hybrid);
## [e.number for e in edges] == [22,23,3] || error("wrong identified edges")
## undoGammaz!(hybrid,net);
## othermaj = getOtherNode(edges[1],hybrid);
## othermaj.number == -6 || error("wrong othermaj")
## edgesmaj = hybridEdges(othermaj);
## [e.number for e in edgesmaj] == [22,5,4] || error("wrong identified edges")
## edgesmaj[3].containRoot || error("wrong edgesmaj[3] contain root")
## undoContainRoot!(edgesRoot);
## [e.containRoot for e in edgesRoot] == [true,true,true] || error("edges root should be false contain root")
## deleteHybrid!(hybrid,net,true, false)
## [e.containRoot for e in edgesRoot] == [true,true,true] || error("edges root should be false contain root")
## printEdges(net)

# ================= delete second hybridization =============================
@testset "delete 2nd hybridization" begin
deleteHybridizationUpdate!(net,net.node[21], false,false);
@test length(net.partition) == 6
# 15,11,10,[9,7,5,3,1,2,4,6,8],17,14
@test [n.number for n in net.partition[1].edges] == [15]
@test [n.number for n in net.partition[2].edges] == [11]
@test [n.number for n in net.partition[3].edges] == [10]
@test [n.number for n in net.partition[4].edges] == [17]
@test [n.number for n in net.partition[5].edges] == [14]
@test [n.number for n in net.partition[6].edges] == [3,1,2,8,6,4,9,7,5]
#printNodes(net)
#printEdges(net)
#printPartitions(net)
@test_nowarn writeTopologyLevel1(net)

# test contain root
@test !net.edge[15].containRoot
@test !net.edge[19].containRoot
@test !net.edge[20].containRoot
@test net.edge[1].containRoot
@test net.edge[2].containRoot
@test net.edge[3].containRoot

# test inCycle
@test net.edge[12].inCycle == 11
@test net.edge[13].inCycle == 11
@test net.edge[16].inCycle == 11
@test net.edge[18].inCycle == 11
@test net.edge[19].inCycle == 11
@test net.edge[20].inCycle == 11

@test net.node[12].inCycle == 11
@test net.node[13].inCycle == 11
@test net.node[16].inCycle == 11
@test net.node[17].inCycle == 11
@test net.node[19].inCycle == 11
@test net.node[20].inCycle == 11
end

# =============== delete first hybridization ===================
@testset "delete 1st hybridization" begin
deleteHybridizationUpdate!(net,net.node[19]);
checkNet(net)
@test length(net.partition) == 0
#printEdges(net)
end
end
