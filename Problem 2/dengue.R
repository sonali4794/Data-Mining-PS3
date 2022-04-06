#modify the dataset and make ready to perform rest of the work
dengue = read_csv(here("Data-Mining-PS3/Problem 2/dengue.csv"))
dengue = na.omit(dengue)
dengue$city = factor(dengue$city)
dengue$season = factor(dengue$season)

#split training and testing data
dengue_split =  initial_split(dengue, prop=0.8)
dengue_train = training(dengue_split)
dengue_test  = testing(dengue_split)

#CART
dengue_cart = rpart(total_cases ~ .,data=dengue_train, 
                    control = rpart.control(cp = 0.00001, minsplit = 20))

# cp_1se = function(my_tree) {
#   out = as.data.frame(my_tree$cptable)
#   thresh = min(out$xerror + out$xstd)
#   cp_opt = max(out$CP[out$xerror <= thresh])
#   cp_opt
# }
# 
# cp_1se(dengue_cart)

prune_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  prune(my_tree, cp=cp_opt)
}

dengue_cart_prune = prune_1se(dengue_cart)

#RandomForest
dengue_forest = randomForest(total_cases ~ ., data=dengue_train, 
                             importance = TRUE)


#boosting
dengue_boost = gbm(total_cases ~ ., 
             data = dengue_train,
             interaction.depth=4, n.trees=500, shrinkage=.05, cv.folds = 10)

#complexity paramete plots
plotcp(dengue_cart)
plot(dengue_forest)
gbm.perf(dengue_boost)

#tabular form of rmse
cart =modelr::rmse(dengue_cart_prune, dengue_test)
rf = modelr::rmse(dengue_forest, dengue_test)
boost = modelr::rmse(dengue_boost, dengue_test)
dengue_rmse = data.frame(round(cart,2), round(rf,2), round(boost,2))
colnames(dengue_rmse) = c("CART","Random Forest","Gradient Boosting")
rownames(dengue_rmse) = "Out of sample error"
dengue_rmse %>%
  kbl()%>%
  kable_material_dark()


#partial plots
vi = varImpPlot(dengue_forest, type=1)
partialPlot(dengue_forest, as.data.frame(dengue_test), 'specific_humidity', las=1)
partialPlot(dengue_forest, as.data.frame(dengue_test), 'precipitation_amt', las=1)
partialPlot(dengue_forest, as.data.frame(dengue_test), 'min_air_temp_k', las=1)



