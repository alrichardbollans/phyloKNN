# Do binary and continuous cases under different evolutionary assumptions
# https://github.com/Matgend/TDIP
# install.packages('nloptr','remotes','devtools')
# install.packages(c('mlr3pipelines', 'missMDA', 'mlr3learners', 'Amelia', 'softImpute', 'missRanger'))
# install.packages(c('missForest', 'VIM'))
# install.packages("NADIA_0.4.2.tar.gz", repos = NULL, type = "source") #https://github.com/Matgend/TDIP?tab=readme-ov-file#installation
# install.packages(c('truncnorm'))
# install.packages("faux_1.2.1.tar.gz", repos = NULL, type = "source") #https://github.com/Matgend/TDIP/issues/1
# remotes::install_version("geiger", version = "2.0.10") # see https://github.com/Matgend/TDIP/issues/1
# packageVersion("geiger")
# install.packages(c('gmp', 'Rmpfr', 'corHMM')) # apt-get install libgmp-dev libmpfr-dev
# remotes::install_github("cran/NADIA")
# devtools::install_github("Matgend/TDIP")

# Gendre Matthieu. 2022. TDIP: Trait Data Imputation with Phylogeny.
library(TDIP)
# save distances, traits and trees to simulation folder, for phylonn to use


# The below redefines the rescaleTree function from TDIP to allow rescaling with both lambda and kappa
unlockBinding("rescaleTree", asNamespace("TDIP"))
rescaleTree <- function(tree, subdata){

  #rescale phylogeny applying lambda transformation BEFORE kappa.
  lambdaCheck <- mean(subdata$lambda)
  kappaCheck <- mean(subdata$kappa)
  subdataTree <- tree
  if(lambdaCheck != 1){
    subdataTree <- geiger::rescale(subdataTree, "lambda", lambdaCheck)
  }

  if (kappaCheck != 1){
    subdataTree <- geiger::rescale(subdataTree, "kappa", kappaCheck)
  }

  return(subdataTree)
}
assign("rescaleTree", rescaleTree, envir = asNamespace("TDIP"))
lockBinding("rescaleTree", asNamespace("TDIP"))



generate_continuous_sample <- function(){
  ev_models = c('BM1', 'OU1')
  ev_model = ev_models[[sample(1:length(ev_models), 1)]]
  lambda = runif(1, min=0, max=1)
  kappa = runif(1, min=0, max=1)
  
  
  continuous_dataframe = data.frame(nbr_traits=c(1),
                                    class=c('continuous'),
                                    model = c(ev_model),
                                    states = c(1),
                                    correlation = c(1),
                                    uncorr_traits = c(1),
                                    fraction_uncorr_traits = c(0),
                                    lambda = c(lambda),
                                    kappa = c(kappa),
                                    highCor = c(0),
                                    manTrait = c(0))
  out <- data_simulator(param_tree = param_tree, dataframe = continuous_dataframe)
  return(out)
}


generate_binary_sample <- function(){
  ev_models = c('ARD', 'SYM', 'ER')
  ev_model = ev_models[[sample(1:length(ev_models), 1)]]
  lambda = runif(1, min=0, max=1)
  kappa = runif(1, min=0, max=1)
  binary_dataframe = data.frame(nbr_traits=c(1),
                                class=c('ordinal'),
                                model = c(ev_model),
                                states = c(2),
                                correlation = c(1),
                                uncorr_traits = c(1),
                                fraction_uncorr_traits = c(0),
                                lambda = c(lambda),
                                kappa = c(kappa),
                                highCor = c(0),
                                manTrait = c(0))
  
  out <- data_simulator(param_tree = param_tree, 
                                  dataframe = binary_dataframe)
  return(out)
}


source('helper_simulation_methods.R')
source('helpful_phyl_methods.R')
dir.create('simulations')
for(i in 1:number_of_repetitions){
  simcontinuousData = generate_continuous_sample()
  target_name = names(simcontinuousData$FinalData)
  # Z-score standardization for the "target" column
  # so that MAE is comparable across different sets
  simcontinuousData$FinalData[target_name] <- scale(simcontinuousData$FinalData[target_name])
  
  tree = simcontinuousData$TreeList$`1`
  ape::is.ultrametric(tree)
  dir.create(file.path('simulations', 'continuous'))
  output_simulation('simulations',simcontinuousData, tree,'continuous', i)
  
}
for(i in 1:number_of_repetitions){
  simbinaryData = generate_binary_sample()
  tree = simbinaryData$TreeList$`1`
  ape::is.ultrametric(tree)
  dir.create(file.path('simulations', 'binary'))
  output_simulation('simulations',simbinaryData, tree,'binary', i)
}
  

