library(aws.s3)
library(tidyverse)
library(stringi)


rstudio_builds <- get_bucket_df("rstudio-ide-build", max = Inf, prefix="server")
rstudio_builds2 <- builds %>%   as_tibble() %>% 
  filter(stri_detect_regex(Key, "\\.deb$"), !stri_detect_fixed(Key, "-pro-"), !stri_detect_fixed(Key, "relwithdebinfo")) %>% 
  extract(Key, into = c("os", "architecture", "prefix", "version"), regex = "server/([\\w\\d]+)/([\\w\\d]+)/rstudio-server-(xenial|stretch)?-?([\\d\\.]+)-[\\w\\d+]+.deb", remove = FALSE) %>% 
  mutate(version = numeric_version(version, strict = FALSE)) 

rstudio_builds2 %>% 
  group_by(os, prefix, architecture, ) %>% 
  summarize(minv = min(version), max=max(version), n = n())



shiny_builds <- get_bucket_df("rstudio-shiny-server-os-build", max = Inf)
View(builds)
shiny_builds2 <- shiny_builds %>% as_tibble() %>% 
  extract(Key, c("os", "arch", "file"), regex = "/?([^/]+)/([^/]+)/(.*)", remove = FALSE) %>% 
  filter(!is.na(os), !is.na(arch), !is.na(file), stri_detect_fixed(file, "shiny-server-")) %>% 
  mutate(version = numeric_version(stri_extract_first_regex(file, "(?<=-)[\\d\\.]+(?=-)")))


shiny_builds2 %>% 
  group_by(os, arch) %>% 
  summarize(minv = min(version), max=max(version), n = n())

