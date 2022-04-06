greenbuildings = read_csv(here("Data-Mining-PS3/Problem 3/greenbuildings.csv")) %>%
  mutate(y = Rent*leasing_rate)
greenbuildings[is.na(greenbuildings)] = 0
#split training and testing data
greenbuildings_split =  initial_split(greenbuildings, prop=0.8)
greenbuildings_train = training(greenbuildings_split)
greenbuildings_test  = testing(greenbuildings_split)

#CART
greenbuildings_cart = rpart(y ~ . - Rent - leasing_rate,data=greenbuildings_train, 
                       control = rpart.control(cp = 0.00001, minsplit = 20))

cp_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  cp_opt
}

cp_1se(greenbuildings_cart)

prune_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  prune(my_tree, cp=cp_opt)
}

greenbuildings_cart_prune = prune_1se(greenbuildings_cart)

#RandomForest
greenbuildings_forest = randomForest(y ~ . - Rent - leasing_rate, data=greenbuildings_train, 
                                importance = TRUE)


#boosting
greenbuildings_boost = gbm(y ~ . - Rent - leasing_rate, 
                      data = greenbuildings_train,
                      interaction.depth=4, n.trees=500, shrinkage=.05, cv.folds = 10)


modelr::rmse(greenbuildings_cart_prune, greenbuildings_test)
modelr::rmse(greenbuildings_forest, greenbuildings_test)
modelr::rmse(greenbuildings_boost, greenbuildings_test)

vi = varImpPlot(greenbuildings_forest, type=1)

partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'age', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'size', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'City_Market_Rent', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'stories', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'amenities', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'class_a', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'class_b', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'cd_total_07', las=1)