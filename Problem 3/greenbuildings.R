#modify the dataset and make it ready for working
greenbuildings = read_csv(here("Data-Mining-PS3/Problem 3/greenbuildings.csv")) %>%
  mutate(revenue = Rent*leasing_rate) %>%
  mutate(green = ifelse(LEED | Energystar, 1, 0)) 
greenbuildings[is.na(greenbuildings)] = 0
#split training and testing data
greenbuildings_split =  initial_split(greenbuildings, prop=0.8)
greenbuildings_train = training(greenbuildings_split)
greenbuildings_test  = testing(greenbuildings_split)

#different modeling approaches to find the best model
#we look at stepwise-LM, stepwise-KNN, CART, random forest, gbm
#stepwise
greenbuildings_baseline = lm(revenue ~ . - CS_PropertyID - LEED - Energystar - Rent - leasing_rate,
                             data = greenbuildings_train)
greenbuildings_stepwise = step(greenbuildings_baseline,
                               direction = "forward",
                               scope = ~(. - CS_PropertyID - LEED - Energystar - Rent - leasing_rate)^2)
greenbuildings_stepwise_lm = lm(revenue ~ cluster + size + empl_gr + stories + age + renovated + 
                                  class_a + class_b + green_rating + net + amenities + cd_total_07 + 
                                  hd_total07 + total_dd_07 + Precipitation + Gas_Costs + Electricity_Costs + 
                                  City_Market_Rent + green + size:City_Market_Rent + cluster:size + 
                                  stories:class_a + cluster:City_Market_Rent + size:Electricity_Costs + 
                                  stories:total_dd_07 + empl_gr:class_a + total_dd_07:City_Market_Rent + 
                                  total_dd_07:Precipitation + Precipitation:Electricity_Costs + 
                                  green_rating:amenities + renovated:Precipitation + class_b:Electricity_Costs + 
                                  renovated:Gas_Costs + total_dd_07:Gas_Costs + renovated:City_Market_Rent + 
                                  age:City_Market_Rent + age:Electricity_Costs + stories:renovated + 
                                  size:renovated + stories:class_b + renovated:total_dd_07 + 
                                  size:stories + size:age + age:class_a + amenities:Electricity_Costs + 
                                  cd_total_07:Gas_Costs + class_a:Gas_Costs + class_b:total_dd_07 + 
                                  cluster:Electricity_Costs + amenities:Precipitation + amenities:Gas_Costs + 
                                  class_b:City_Market_Rent + size:hd_total07 + cluster:hd_total07 + 
                                  net:total_dd_07 + class_a:amenities + empl_gr:Gas_Costs + 
                                  stories:cd_total_07 + stories:age + size:cd_total_07 + total_dd_07:Electricity_Costs + 
                                  size:Gas_Costs + green_rating:hd_total07, data = greenbuildings_train)


## knn model

# knn model
knn_grid = seq(1, 500, by=5)
greenbuildings_knn_grid = foreach(k = knn_grid, .combine='rbind') %do% {
  model = knnreg(revenue ~ cluster + size + empl_gr + stories + age + renovated + 
                   class_a + class_b + green_rating + net + amenities + cd_total_07 + 
                   hd_total07 + total_dd_07 + Precipitation + Gas_Costs + Electricity_Costs + 
                   City_Market_Rent + green, k=k, data = greenbuildings_train)
  rms = modelr::rmse(model, greenbuildings_test)
  c(k=k, err=rms)
} %>% as.data.frame
knn = min(greenbuildings_knn_grid$err)


#CART
greenbuildings_cart = rpart(revenue ~ . - CS_PropertyID - LEED - Energystar - Rent - leasing_rate,data=greenbuildings_train, 
                       control = rpart.control(cp = 0.00001, minsplit = 20))

# cp_1se = function(my_tree) {
#   out = as.data.frame(my_tree$cptable)
#   thresh = min(out$xerror + out$xstd)
#   cp_opt = max(out$CP[out$xerror <= thresh])
#   cp_opt
# }
# 
# cp_1se(greenbuildings_cart)

prune_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  prune(my_tree, cp=cp_opt)
}

greenbuildings_cart_prune = prune_1se(greenbuildings_cart)

#RandomForest
greenbuildings_forest = randomForest(revenue ~ . - CS_PropertyID - LEED - Energystar - Rent - leasing_rate, data=greenbuildings_train, 
                                importance = TRUE)


#boosting
greenbuildings_boost = gbm(revenue ~ . - CS_PropertyID - LEED - Energystar - Rent - leasing_rate, 
                      data = greenbuildings_train,
                      interaction.depth=4, n.trees=500, shrinkage=.05, cv.folds = 10)

lm = modelr::rmse(greenbuildings_stepwise_lm, greenbuildings_test)
cart = modelr::rmse(greenbuildings_cart_prune, greenbuildings_test)
rf = modelr::rmse(greenbuildings_forest, greenbuildings_test)
boost = modelr::rmse(greenbuildings_boost, greenbuildings_test)

greenbuildings_rmse = data.frame(round(lm,2),round(knn,2),round(cart,2), round(rf,2), round(boost,2))
colnames(greenbuildings_rmse) = rbind("Linear Model","KNN","CART","Random Forest","Gradient Boosting")
rownames(greenbuildings_rmse) = "Out of sample error"
greenbuildings_rmse %>%
  kbl()%>%
  kable_material_dark()

vi = varImpPlot(greenbuildings_forest, type=1)

df = greenbuildings_test %>%
  select(revenue, green) %>%
  mutate(revenue_hat = predict(greenbuildings_forest, newdata = greenbuildings_test))
a1 = mean(subset(df, green==1)$revenue_hat)
a0 = mean(subset(df, green==0)$revenue_hat)
avg_rental_chng = a1-a0
avg_rental_chng
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'green', las=1)

partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'size', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'age', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'City_Market_Rent', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'stories', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'amenities', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'class_a', las=1)
partialPlot(greenbuildings_forest, as.data.frame(greenbuildings_test), 'cluster', las=1)