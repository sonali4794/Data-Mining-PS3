cahousing = read_csv(here("Data-Mining-PS3/Problem 4/CAhousing.csv"))
#split training and testing data
cahousing_split =  initial_split(cahousing, prop=0.8)
cahousing_train = training(cahousing_split)
cahousing_test  = testing(cahousing_split)

#CART
cahousing_cart = rpart(medianHouseValue ~ .,data=cahousing_train, 
                    control = rpart.control(cp = 0.00001, minsplit = 20))

# cp_1se = function(my_tree) {
#   out = as.data.frame(my_tree$cptable)
#   thresh = min(out$xerror + out$xstd)
#   cp_opt = max(out$CP[out$xerror <= thresh])
#   cp_opt
# }
# 
# cp_1se(cahousing_cart)

prune_1se = function(my_tree) {
  out = as.data.frame(my_tree$cptable)
  thresh = min(out$xerror + out$xstd)
  cp_opt = max(out$CP[out$xerror <= thresh])
  prune(my_tree, cp=cp_opt)
}

cahousing_cart_prune = prune_1se(cahousing_cart)

#RandomForest
cahousing_forest = randomForest(medianHouseValue ~ ., data=cahousing_train, 
                             importance = TRUE)


#boosting
cahousing_boost = gbm(medianHouseValue ~ ., 
                   data = cahousing_train,
                   interaction.depth=4, n.trees=500, shrinkage=.05, cv.folds = 10)



cart=modelr::rmse(cahousing_cart_prune, cahousing_test)
rf=modelr::rmse(cahousing_forest, cahousing_test)
boost=modelr::rmse(cahousing_boost, cahousing_test)

cahousing_rmse = data.frame(round(cart,2), round(rf,2), round(boost,2))
colnames(cahousing_rmse) = c("CART","Random Forest","Gradient Boosting")
rownames(cahousing_rmse) = "Out of sample error"
cahousing_rmse %>%
  kbl()%>%
  kable_material_dark()

plotcp(cahousing_cart)
plot(cahousing_forest)
gbm.perf(cahousing_boost)

vi = varImpPlot(cahousing_forest, type=1)
partialPlot(cahousing_forest, as.data.frame(cahousing_test), 'medianIncome', las=1)
partialPlot(cahousing_forest, as.data.frame(cahousing_test), 'housingMedianAge', las=1)
partialPlot(cahousing_forest, as.data.frame(cahousing_test), 'population', las=1)
partialPlot(cahousing_forest, as.data.frame(cahousing_test), 'latitude', las=1)
partialPlot(cahousing_forest, as.data.frame(cahousing_test), 'longitude', las=1)
partialPlot(cahousing_forest, as.data.frame(cahousing_test), 'totalBedrooms', las=1)
partialPlot(cahousing_forest, as.data.frame(cahousing_test), 'households', las=1)
partialPlot(cahousing_forest, as.data.frame(cahousing_test), 'totalRooms', las=1)

yhat_rf = predict(cahousing_forest, cahousing_test)
resid_rf = yhat_rf - cahousing$medianHouseValue

df = data.frame(cbind(LAT=cahousing_test$latitude, LONG=cahousing_test$longitude,
                VALUE=cahousing_test$medianHouseValue,yhat_rf,resid_rf)) %>%
  mutate(group = 1)

states = map_data("state")
ca_df = subset(states, region == "california")
counties = map_data("county")
ca_county = subset(counties, region == "california")
options(scipen = 999)
ggplot(data = ca_df, mapping = aes(x = lat, y = long, group = group)) + 
  coord_fixed(1.3) + 
  geom_polygon(color = "black", fill = "gray") +
  geom_polygon(data = ca_county, fill = NA, color = "black") +
  geom_point(data = df, aes(x=LAT, y=LONG, color = resid_rf))+
  scale_color_gradient(low = "blue", high = "red") +
  labs(x="Latitude", y="Longitude", title = "Model's Residual between the actual and predicted housing median value", color = "Residual")


ggplot(data = ca_df, mapping = aes(x = lat, y = long, group = group)) + 
  coord_fixed(1.3) + 
  geom_polygon(color = "black", fill = "gray") +
  geom_polygon(data = ca_county, fill = NA, color = "black") +
  geom_polygon(color = "black", fill = NA)+
  geom_point(data = df, aes(x=LAT, y=LONG, color = yhat_rf))+
  scale_color_gradient(low = "blue", high = "red") +
  labs(x="Latitude", y="Longitude", title = "Predicted Median Market Value of Households in California", color = "Predicted Median Value")

ggplot(data = ca_df, mapping = aes(x = lat, y = long, group = group)) + 
  coord_fixed(1.3) + 
  geom_polygon(color = "black", fill = "gray") +
  geom_polygon(data = ca_county, fill = NA, color = "black") +
  geom_polygon(color = "black", fill = NA)+
  geom_point(data = df, aes(x=LAT, y=LONG, color = VALUE))+
  scale_color_gradient(low = "blue", high = "red") +
  labs(x="Latitude", y="Longitude", title = "Median Market value of households in California", color = "Actual Median Value")


