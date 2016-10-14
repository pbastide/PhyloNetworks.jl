## Test of PhyloNetworklm
## still not an automatic test function, needs work

using PhyloNetworks
using GLM
using DataFrames
using Base.Test
#include("../src/types.jl")
#include("../src/functions.jl")
#include("../src/traits.jl")

tree= "(A,((B,#H1),(C,(D)#H1)));"
net=readTopologyLevel1(tree)
#printEdges(net)

# Re-root the tree so that it matches my example
rootatnode!(net, "A")
printEdges(net)
preorder!(net)
# plot(net, useEdgeLength = true,  showEdgeNumber=true)

# Make the network ultrametric
net.edge[1].length = 2.5
net.edge[6].length = 0.5
net.edge[7].length = 0.5
net.edge[3].length = 0.5
# plot(net, useEdgeLength = true)
# Rk: Is there a way to check that the branch length are coherents with 
# one another (Especialy for hybrids) ?

# Ancestral state reconstruction with ready-made matrices
params = paramsBM(10, 1)
sim = simulate(net, params)
Y = sim[:Tips]
X = ones(4, 1)
phynetlm = phyloNetworklm(X, Y, net)
@show phynetlm
# Naive version (GLS)
ntaxa = length(Y)
Vy = phynetlm.Vy
Vyinv = inv(Vy)
XtVyinv = X' * Vyinv
logdetVy = logdet(Vy)
betahat = inv(XtVyinv * X) * XtVyinv * Y
fittedValues =  X * betahat
resids = Y - fittedValues
sigma2hat = 1/ntaxa * (resids' * Vyinv * resids)
 # log likelihood
loglik = - 1 / 2 * (ntaxa + ntaxa * log(2 * pi) + ntaxa * log(sigma2hat) + logdetVy)
# null version
nullX = ones(ntaxa, 1)
nullXtVyinv = nullX' * Vyinv
nullresids = Y - nullX * inv(nullXtVyinv * nullX) * nullXtVyinv * Y 
nullsigma2hat = 1/ntaxa * (nullresids' * Vyinv * nullresids)
nullloglik = - 1 / 2 * (ntaxa + ntaxa * log(2 * pi) + ntaxa * log(nullsigma2hat) + logdetVy)


@test_approx_eq coef(phynetlm) betahat
@test_approx_eq nobs(phynetlm) ntaxa
@test_approx_eq residuals(phynetlm) resids
@test_approx_eq model_response(phynetlm) Y
@test_approx_eq predict(phynetlm) fittedValues
@test_approx_eq dof_residual(phynetlm) ntaxa-length(betahat)
@test_approx_eq sigma2_estim(phynetlm) sigma2hat 
@test_approx_eq loglikelihood(phynetlm) loglik
@test_approx_eq vcov(phynetlm) sigma2hat*ntaxa/(ntaxa-length(betahat))*inv(XtVyinv * X)
@test_approx_eq stderr(phynetlm) sqrt(diag(sigma2hat*ntaxa/(ntaxa-length(betahat))*inv(XtVyinv * X)))
@test_approx_eq dof(phynetlm)  length(betahat)+1
@test_approx_eq deviance(phynetlm) sigma2hat * ntaxa
@test_approx_eq nulldeviance(phynetlm) nullsigma2hat * ntaxa 
@test_approx_eq nullloglikelihood(phynetlm) nullloglik
@test_approx_eq loglikelihood(phynetlm) nullloglikelihood(phynetlm)
@test_approx_eq deviance(phynetlm) nulldeviance(phynetlm)
#@test_approx_eq r2(phynetlm) 1-sigma2hat / nullsigma2hat 
#@test_approx_eq adjr2(phynetlm) 1 - (1 - (1-sigma2hat/nullsigma2hat))*(ntaxa-1)/(ntaxa-length(betahat)) 
@test_approx_eq aic(phynetlm) -2*loglik+2*(length(betahat)+1)
@test_approx_eq aicc(phynetlm) -2*loglik+2*(length(betahat)+1)+2(length(betahat)+1)*((length(betahat)+1)+1)/(ntaxa-(length(betahat)+1)-1)
@test_approx_eq bic(phynetlm) -2*loglik+(length(betahat)+1)*log(ntaxa)

# with data frames
dfr = DataFrame(trait = Y, tipsNames = sim.M.tipsNames)
fitbis = phyloNetworklm(trait ~ 1, dfr, net)
@show fitbis

@test_approx_eq coef(phynetlm) coef(fitbis)
@test_approx_eq vcov(phynetlm) vcov(fitbis)
@test_approx_eq nobs(phynetlm) nobs(fitbis)
@test_approx_eq residuals(phynetlm)[fitbis.model.ind] residuals(fitbis)
@test_approx_eq model_response(phynetlm)[fitbis.model.ind] model_response(fitbis)
@test_approx_eq predict(phynetlm)[fitbis.model.ind] predict(fitbis)
@test_approx_eq dof_residual(phynetlm) dof_residual(fitbis)
@test_approx_eq sigma2_estim(phynetlm) sigma2_estim(fitbis)
@test_approx_eq stderr(phynetlm) stderr(fitbis)
@test_approx_eq confint(phynetlm) confint(fitbis)
@test_approx_eq loglikelihood(phynetlm) loglikelihood(fitbis)
@test_approx_eq dof(phynetlm)  dof(fitbis)
@test_approx_eq deviance(phynetlm)  deviance(fitbis)
@test_approx_eq nulldeviance(phynetlm)  nulldeviance(fitbis)
@test_approx_eq nullloglikelihood(phynetlm)  nullloglikelihood(fitbis)
@test_approx_eq r2(phynetlm)  r2(fitbis)
@test_approx_eq adjr2(phynetlm)  adjr2(fitbis)
@test_approx_eq aic(phynetlm)  aic(fitbis)
@test_approx_eq aicc(phynetlm)  aicc(fitbis)
@test_approx_eq bic(phynetlm)  bic(fitbis)
@test_approx_eq mu_estim(phynetlm)  mu_estim(fitbis)

#### Other Network ###
net = readTopology("(((Ag,(#H1:7.159::0.056,((Ak,(E:0.08,#H2:0.0::0.004):0.023):0.078,(M:0.0)#H2:::0.996):2.49):2.214):0.026,(((((Az:0.002,Ag2:0.023):2.11,As:2.027):1.697)#H1:0.0::0.944,Ap):0.187,Ar):0.723):5.943,(P,20):1.863,165);");

# Make it ultrametric
for i = 1:27
	net.edge[i].length = 1
end
net.edge[27].length = 7
net.edge[26].length = 3
net.edge[25].length = 4
net.edge[24].length = 4
net.edge[21].length = 5
net.edge[19].length = 4
net.edge[16].length = 2
net.edge[8].length = 2
net.edge[3].length = 2
net.edge[1].length = 5

plot(net, useEdgeLength = true,  showEdgeNumber=true)

#### Simulate correlated data in data frames ####
b0 = 1
b1 = 10
sim = simulate(net, paramsBM(1, 1))
A = sim[:Tips]
B = b0 + b1 * A + simulate(net,  paramsBM(0, 0.1))[:Tips]

# With Matrices
X = hcat(ones(12), A)
fit_mat = phyloNetworklm(X, B, net)
@show fit_mat

# Naive version (GLS)
ntaxa = length(B)
Vy = fit_mat.Vy
Vyinv = inv(Vy)
XtVyinv = X' * Vyinv
logdetVy = logdet(Vy)
betahat = inv(XtVyinv * X) * XtVyinv * B
fittedValues =  X * betahat
resids = B - fittedValues
sigma2hat = 1/ntaxa * (resids' * Vyinv * resids)
# log likelihood
loglik = - 1 / 2 * (ntaxa + ntaxa * log(2 * pi) + ntaxa * log(sigma2hat) + logdetVy)
# null version
nullX = ones(ntaxa, 1)
nullXtVyinv = nullX' * Vyinv
nullresids = B - nullX * inv(nullXtVyinv * nullX) * nullXtVyinv * B
nullsigma2hat = 1/ntaxa * (nullresids' * Vyinv * nullresids)
nullloglik = - 1 / 2 * (ntaxa + ntaxa * log(2 * pi) + ntaxa * log(nullsigma2hat) + logdetVy)
@test_approx_eq coef(fit_mat) betahat
@test_approx_eq nobs(fit_mat) ntaxa
@test_approx_eq residuals(fit_mat) resids
@test_approx_eq model_response(fit_mat) B
@test_approx_eq predict(fit_mat) fittedValues
@test_approx_eq dof_residual(fit_mat) ntaxa-length(betahat)
@test_approx_eq sigma2_estim(fit_mat) sigma2hat
@test_approx_eq loglikelihood(fit_mat) loglik
@test_approx_eq vcov(fit_mat) sigma2hat*ntaxa/(ntaxa-length(betahat)).*inv(XtVyinv * X)
@test_approx_eq stderr(fit_mat) sqrt(diag(sigma2hat*ntaxa/(ntaxa-length(betahat)).*inv(XtVyinv * X)))
@test_approx_eq dof(fit_mat)  length(betahat)+1
@test_approx_eq deviance(fit_mat) sigma2hat * ntaxa
@test_approx_eq nulldeviance(fit_mat) nullsigma2hat * ntaxa
@test_approx_eq nullloglikelihood(fit_mat) nullloglik
@test_approx_eq r2(fit_mat) 1-sigma2hat / nullsigma2hat
@test_approx_eq adjr2(fit_mat) 1 - (1 - (1-sigma2hat/nullsigma2hat))*(ntaxa-1)/(ntaxa-length(betahat))
@test_approx_eq aic(fit_mat) -2*loglik+2*(length(betahat)+1)
@test_approx_eq aicc(fit_mat) -2*loglik+2*(length(betahat)+1)+2(length(betahat)+1)*((length(betahat)+1)+1)/(ntaxa-(length(betahat)+1)-1)
@test_approx_eq bic(fit_mat) -2*loglik+(length(betahat)+1)*log(ntaxa)

## perfect user using right format and formula
dfr = DataFrame(trait = B, pred = A, tipsNames = sim.M.tipsNames)
phynetlm = phyloNetworklm(trait ~ pred, dfr, net)
@show phynetlm

@test_approx_eq coef(phynetlm) coef(fit_mat)
@test_approx_eq vcov(phynetlm) vcov(fit_mat)
@test_approx_eq nobs(phynetlm) nobs(fit_mat)
@test_approx_eq residuals(phynetlm) residuals(fit_mat)
@test_approx_eq model_response(phynetlm) model_response(fit_mat)
@test_approx_eq predict(phynetlm) predict(fit_mat)
@test_approx_eq dof_residual(phynetlm) dof_residual(fit_mat)
@test_approx_eq sigma2_estim(phynetlm) sigma2_estim(fit_mat)
@test_approx_eq stderr(phynetlm) stderr(fit_mat)
@test_approx_eq confint(phynetlm) confint(fit_mat)
@test_approx_eq loglikelihood(phynetlm) loglikelihood(fit_mat)
@test_approx_eq dof(phynetlm)  dof(fit_mat)
@test_approx_eq deviance(phynetlm)  deviance(fit_mat)
@test_approx_eq nulldeviance(phynetlm)  nulldeviance(fit_mat)
@test_approx_eq nullloglikelihood(phynetlm)  nullloglikelihood(fit_mat)
@test_approx_eq r2(phynetlm)  r2(fit_mat)
@test_approx_eq adjr2(phynetlm)  adjr2(fit_mat)
@test_approx_eq aic(phynetlm)  aic(fit_mat)
@test_approx_eq aicc(phynetlm)  aicc(fit_mat)
@test_approx_eq bic(phynetlm)  bic(fit_mat)



# unordered data
dfr = dfr[sample(1:12, 12, replace=false), :]
fitbis = phyloNetworklm(trait ~ pred, dfr, net)

@test_approx_eq coef(phynetlm) coef(fitbis)
@test_approx_eq vcov(phynetlm) vcov(fitbis)
@test_approx_eq nobs(phynetlm) nobs(fitbis)
@test_approx_eq residuals(phynetlm)[fitbis.model.ind] residuals(fitbis)
@test_approx_eq model_response(phynetlm)[fitbis.model.ind] model_response(fitbis)
@test_approx_eq predict(phynetlm)[fitbis.model.ind] predict(fitbis)
@test_approx_eq dof_residual(phynetlm) dof_residual(fitbis)
@test_approx_eq sigma2_estim(phynetlm) sigma2_estim(fitbis)
@test_approx_eq stderr(phynetlm) stderr(fitbis)
@test_approx_eq confint(phynetlm) confint(fitbis)
@test_approx_eq loglikelihood(phynetlm) loglikelihood(fitbis)
@test_approx_eq dof(phynetlm)  dof(fitbis)
@test_approx_eq deviance(phynetlm)  deviance(fitbis)
@test_approx_eq nulldeviance(phynetlm)  nulldeviance(fitbis)
@test_approx_eq nullloglikelihood(phynetlm)  nullloglikelihood(fitbis)
@test_approx_eq r2(phynetlm)  r2(fitbis)
@test_approx_eq adjr2(phynetlm)  adjr2(fitbis)
@test_approx_eq aic(phynetlm)  aic(fitbis)
@test_approx_eq aicc(phynetlm)  aicc(fitbis)
@test_approx_eq bic(phynetlm)  bic(fitbis)
@test_approx_eq mu_estim(phynetlm)  mu_estim(fitbis)


# unnamed ordered data
dfr = DataFrame(trait = B, pred = A)
fitter = phyloNetworklm(trait ~ pred, dfr, net, no_names=true)

@test_approx_eq coef(phynetlm) coef(fitter)
@test_approx_eq vcov(phynetlm) vcov(fitter)
@test_approx_eq nobs(phynetlm) nobs(fitter)
@test_approx_eq residuals(phynetlm) residuals(fitter)
@test_approx_eq model_response(phynetlm) model_response(fitter)
@test_approx_eq predict(phynetlm) predict(fitter)
@test_approx_eq dof_residual(phynetlm) dof_residual(fitter)
@test_approx_eq sigma2_estim(phynetlm) sigma2_estim(fitter)
@test_approx_eq stderr(phynetlm) stderr(fitter)
@test_approx_eq confint(phynetlm) confint(fitter)
@test_approx_eq loglikelihood(phynetlm) loglikelihood(fitter)
@test_approx_eq dof(phynetlm)  dof(fitter)
@test_approx_eq deviance(phynetlm)  deviance(fitter)
@test_approx_eq nulldeviance(phynetlm)  nulldeviance(fitter)
@test_approx_eq nullloglikelihood(phynetlm)  nullloglikelihood(fitter)
@test_approx_eq r2(phynetlm)  r2(fitter)
@test_approx_eq adjr2(phynetlm)  adjr2(fitter)
@test_approx_eq aic(phynetlm)  aic(fitter)
@test_approx_eq aicc(phynetlm)  aicc(fitter)
@test_approx_eq bic(phynetlm)  bic(fitter)


# unnamed un-ordered data
dfr = dfr[sample(1:12, 12, replace=false), :]
@test_throws ErrorException fitter = phyloNetworklm(trait ~ pred, dfr, net) # Wrong pred


### Add NAs
dfr = DataFrame(trait = B, pred = A, tipsNames = tipLabels(sim))
dfr[[2, 8, 11], :pred] = NA
fitna = phyloNetworklm(trait ~ pred, dfr, net)
@show fitna

dfr = dfr[sample(1:12, 12, replace=false), :]
fitnabis = phyloNetworklm(trait ~ pred, dfr, net)

@test_approx_eq coef(fitna) coef(fitnabis)
@test_approx_eq vcov(fitna) vcov(fitnabis)
@test_approx_eq nobs(fitna) nobs(fitnabis)
@test_approx_eq sort(residuals(fitna)) sort(residuals(fitnabis))
@test_approx_eq sort(model_response(fitna)) sort(model_response(fitnabis))
@test_approx_eq sort(predict(fitna)) sort(predict(fitnabis))
@test_approx_eq dof_residual(fitna) dof_residual(fitnabis)
@test_approx_eq sigma2_estim(fitna) sigma2_estim(fitnabis)
@test_approx_eq stderr(fitna) stderr(fitnabis)
@test_approx_eq confint(fitna) confint(fitnabis)
@test_approx_eq loglikelihood(fitna) loglikelihood(fitnabis)
@test_approx_eq dof(fitna)  dof(fitnabis)
@test_approx_eq deviance(fitna)  deviance(fitnabis)
@test_approx_eq nulldeviance(fitna)  nulldeviance(fitnabis)
@test_approx_eq nullloglikelihood(fitna)  nullloglikelihood(fitnabis)
@test_approx_eq r2(fitna)  r2(fitnabis)
@test_approx_eq adjr2(fitna)  adjr2(fitnabis)
@test_approx_eq aic(fitna)  aic(fitnabis)
@test_approx_eq aicc(fitna)  aicc(fitnabis)
@test_approx_eq bic(fitna)  bic(fitnabis)



### Ancestral State Reconstruction
params = paramsBM(3, 1)
sim = simulate(net, params)
Y = sim[:Tips]
# From known parameters
ancestral_traits = ancestralStateReconstruction(net, Y, params)
# BLUP
dfr = DataFrame(trait = Y, tipsNames = tipLabels(sim))
phynetlm = phyloNetworklm(trait~1, dfr, net)
blup = ancestralStateReconstruction(phynetlm)
plot(net, blup)

# BLUP same, using the function dirrectly
blup_bis = ancestralStateReconstruction(dfr, net)

@test_approx_eq expectations(blup)[:condExpectation] expectations(blup_bis)[:condExpectation]
@test_approx_eq expectations(blup)[:nodeNumber] expectations(blup_bis)[:nodeNumber]
@test_approx_eq blup.traits_tips blup_bis.traits_tips
@test_approx_eq blup.TipsNumbers blup_bis.TipsNumbers
@test_approx_eq predint(blup) predint(blup_bis)

dfr = DataFrame(trait = Y, tipsNames = tipLabels(sim), reg = Y)
@test_throws ErrorException fitter = ancestralStateReconstruction(dfr, net) # cannot handle a predictor

# Unordered
dfr2 = dfr[sample(1:12, 12, replace=false), :]
phynetlm = phyloNetworklm(trait~1, dfr2, net)
blup2 = ancestralStateReconstruction(phynetlm)

@test_approx_eq expectations(blup)[:condExpectation][1:length(blup.NodesNumbers)] expectations(blup2)[:condExpectation][1:length(blup.NodesNumbers)]
@test_approx_eq blup.traits_tips[phynetlm.model.ind] blup2.traits_tips
@test_approx_eq blup.TipsNumbers[phynetlm.model.ind] blup2.TipsNumbers
@test_approx_eq predint(blup)[1:length(blup.NodesNumbers), :] predint(blup2)[1:length(blup.NodesNumbers), :]

# With unknown tips
dfr[[2, 4], :trait] = NA
phynetlm = phyloNetworklm(trait~1, dfr, net)
blup = ancestralStateReconstruction(phynetlm)
plot(net, blup)

# Unordered
dfr2 = dfr[[1, 2, 5, 3, 4, 6, 7, 8, 9, 10, 11, 12], :]
phynetlm = phyloNetworklm(trait~1, dfr, net)
blup2 = ancestralStateReconstruction(phynetlm)

@test_approx_eq expectations(blup)[:condExpectation][1:length(blup.NodesNumbers)] expectations(blup2)[:condExpectation][1:length(blup.NodesNumbers)]
@test_approx_eq predint(blup)[1:length(blup.NodesNumbers), :] predint(blup2)[1:length(blup.NodesNumbers), :]

