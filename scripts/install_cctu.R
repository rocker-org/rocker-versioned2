# for use outside of gitworkflow. This uses run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
# drop the repo=r argument to git_remote_ls 

r <- tempfile(pattern = "gert")
git_init(r)


df_cctu <- gert::git_remote_ls(remote = "https://github.com/shug0131/cctu.git", repo=r)|>
  dplyr::filter(stringr::str_detect(ref, "^refs/tags/[vV]?")) |>
  dplyr::mutate(
    cctu_version = stringr::str_extract(ref, r"([vV]?\d+\.\d+\.\d+.{0,1}\d*.*)"),
    commit_url = glue::glue("https://api.github.com/repos/shug0131/cctu/commits/{oid}"),
    .keep = "none"
  ) |>
  dplyr::slice_tail(n = 10) |>
  dplyr::rowwise() |>
  dplyr::mutate(cctu_commit_date = .get_github_commit_date(commit_url)) |>
  dplyr::ungroup() |>
  tidyr::drop_na() |>
  dplyr::select(
    cctu_version,
    cctu_commit_date
  ) |>
  dplyr::arrange(cctu_commit_date)

cctu_version = df_cctu |> ungroup() |> dplyr::slice_max(cctu_commit_date) |> pull("cctu_version")

# the above goes in make-stacks.
# and revise devel.json to have a section for cctu with cctu_version as an ENV variable

#Below goes into install_cctu.sh 

NCPUS=${NCPUS:--1}

install2.r --error --skipinstalled -n "$NCPUS" \
    xslt\     # cctu depends 
    kableExtra\
    reshape2\  # data warngling old school
    ggalluvial\ # nice plots
    patchwork\ # gluing together plots (soon to be CCTU depends)
    writexl\ # write to excel
    openxlsx\ # formatting tools within excel
    gee \ # stats package for GEE
    lme4 \# mixed models
    eudract \ # outputs for clintrials and eudract
    ordinal \ # categorcial variable regression
    consort \ # consort diagram generator
    coxme \ # mixed effect survival analysis 
    mice  # multiple imputation tool box
#    Hmisc \ # frnak harrells package of stuff
#   mfp \ # fractional polynomials 
#  stan packages ??
#  

R -q -e 'remotes::install_github(repo="shug0131/cctu", ref="$cctu_version" )'
