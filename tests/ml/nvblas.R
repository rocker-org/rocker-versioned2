install.packages("callr")

system.time(
callr::r(function(){
  N <- 2^14
  M <- matrix(rnorm(N*N), nrow=N, ncol=N)
  M %*% M
  }, env = c(LD_PRELOAD="libnvblas.so"))
)


