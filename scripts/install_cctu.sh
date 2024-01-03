# for use outside of gitworkflow. This uses run: git config --global --add safe.directory "$GITHUB_WORKSPACE"
r <- tempfile(pattern = "gert")
git_init(r)

df_cctu <- gert::git_remote_ls(remote = "https://github.com/shug0131/cctu.git", repo=r)|>
  dplyr::filter(stringr::str_detect(ref, "^refs/tags/[vV]")) |>
  dplyr::mutate(
    cctu_version = stringr::str_extract(ref, r"(\d+\.\d+\.\d+.{0,1}\d*.*)"),
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

latest_cctu = df_cctu |> ungroup() |> dplyr::slice_head() |> pull("cctu_version")

remotes::install_github(repo="shug0131/cctu", ref=latest_cctu)