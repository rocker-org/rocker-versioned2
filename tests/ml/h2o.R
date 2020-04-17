

library(xgboost)
# load data
data(agaricus.train, package = 'xgboost')
data(agaricus.test, package = 'xgboost')
train <- agaricus.train
test <- agaricus.test
# fit model
bst <- xgboost(data = train$data, label = train$label, max_depth = 5, eta = 0.001, nrounds = 100,
               nthread = 2, objective = "binary:logistic", tree_method = "gpu_hist")

# Test for multi-gpu support
#bst <- xgboost(data = train$data, label = train$label, max_depth = 5, eta = 0.001, nrounds = 10000,
#               nthread = 2, objective = "binary:logistic", tree_method = "gpu_hist", n_gpus=4)

# predict
pred <- predict(bst, test$data)



## Xgboost via H2O Test
## `h2o` provides a nice interface to `xgboost`, along with some great tools for hyper-parameter tuning. (*Note: This is not an install of `h2o4gpu` so only `h2o.xgboost` supports GPU acceleration.*)



# Init h2o
library(h2o)
h2o.init()
# Load test data
australia_path <- system.file("extdata", "australia.csv", package = "h2o")
australia <- h2o.uploadFile(path = australia_path)
independent <- c("premax", "salmax","minairtemp", "maxairtemp", "maxsst",
                 "maxsoilmoist", "Max_czcs")
dependent <- "runoffnew"
# Run xgboost without GPU
h2o.xgboost(y = dependent, x = independent, training_frame = australia,
        ntrees = 1000, backend = "cpu")
# Run xgboost with GPU
h2o.xgboost(y = dependent, x = independent, training_frame = australia,
            ntrees = 1000, backend = "gpu")

## h2o stress test
h2o.xgboost(y = dependent, x = independent, training_frame = australia,
            ntrees = 100000, backend = "gpu")


