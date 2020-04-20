AppendScoresToLineList <- function(linelist, reference_list, scores) {

  # Append to the line list, for each case: closest disease, corresponding highest score, and the scores for
  # each disease.
  # linelist is a list list(mat = line list as matrix of lists, df = line list as data frame)
  # It returns a similar list, with disease and scores appended.

  ll_sc_mat <- linelist$mat
  ll_sc_df <- linelist$df
  for (nr in names(reference_list)) {
    score_vec <- sapply(linelist$mat[,'case_id'],
      function (ci) scores %>% filter(case_id == ci, reference == nr) %>% pull(s1) %>% round(digits=2))
    ll_sc_mat <- cbind(ll_sc_mat, score_vec)
    ll_sc_df <- cbind(ll_sc_df, score_vec)
    colnames(ll_sc_mat)[ncol(ll_sc_mat)] <- paste('score /',nr)
    colnames(ll_sc_df)[ncol(ll_sc_df)] <- paste('score /',nr)
  }

  highest_score_vec <- sapply(linelist$mat[,'case_id'],
    function (ci)
      scores %>% filter(case_id == ci,
        s1 == max(scores %>% filter(case_id == ci) %>% pull(s1))) %>%
      pull(reference) %>% as.character())
  closest_disease_vec <- sapply(linelist$mat[,'case_id'],
    function (ci) max(scores %>% filter(case_id == ci) %>% pull(s1) %>% round(digits=2)))

  ll_sc_mat <- cbind(ll_sc_mat,highest_score_vec)
  ll_sc_df <- cbind(ll_sc_df,highest_score_vec)
  ll_sc_mat <- cbind(ll_sc_mat,closest_disease_vec)
  ll_sc_df <- cbind(ll_sc_df,closest_disease_vec)

  colnames(ll_sc_mat)[c(ncol(ll_sc_mat)-1,ncol(ll_sc_mat))] <- c('closest disease','highest score')
  colnames(ll_sc_df)[c(ncol(ll_sc_df)-1,ncol(ll_sc_df))] <- c('closest disease','highest score')

  first_columns <- c(c('case_id','closest disease','highest score'),
    sapply(names(reference_list), function (nr) paste('score /', nr)))
  ll_sc_mat <- ll_sc_mat[, c(first_columns, colnames(ll_sc_mat)[!colnames(ll_sc_mat)%in%first_columns])]
  ll_sc_df <- ll_sc_df[, c(first_columns, colnames(ll_sc_df)[!colnames(ll_sc_df)%in%first_columns])]

  return(list(mat=ll_sc_mat,df=ll_sc_df))

}
