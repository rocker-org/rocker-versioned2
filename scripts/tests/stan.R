library(cmdstanr)
# Generate some fake data
n <- 250000
k <- 20
X <- matrix(rnorm(n * k), ncol = k)
y <- rbinom(n, size = 1, prob = plogis(3 * X[,1] - 2 * X[,2] + 1))
mdata <- list(k = k, n = n, y = y, X = X)
download.file("https://raw.githubusercontent.com/stan-dev/cmdstanr/master/vignettes/articles-online-only/opencl-files/bernoulli_logit_glm.stan", destfile = "test.stan")
mod_cl <- cmdstan_model("test.stan",
                        cpp_options = list(stan_opencl = TRUE))
fit_cl <- mod_cl$sample(data = mdata, chains = 4, parallel_chains = 4,
                        opencl_ids = c(0, 0), refresh = 0)
