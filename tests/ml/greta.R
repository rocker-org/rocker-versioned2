
## Installation: set up a separate virtualenv
library(reticulate)
virtualenv_create("/opt/venv/greta")
use_virtualenv("/opt/venv/greta")
py_install("tensorflow-probability==0.7.0")
py_install("tensorflow-gpu==1.14.0")
py_install("numpy")
py_discover_config()
install.packages("greta")

## Greta test -- should run on GPU if available
library(greta)
x <- iris$Petal.Length
y <- iris$Sepal.Length
int <- normal(0, 5)
coef <- normal(0, 3)
sd <- lognormal(0, 3)
mean <- int + coef * x
distribution(y) <- normal(mean, sd)
m <- greta::model(int, coef, sd)
draws <- greta::mcmc(m, n_samples = 1000, chains = 4)



