ComputeScores <- function(linelist, linelist_name, reference_list, data_dict) {

  # DEBUG:
  # linelist <- ll_mat
  # linelist_name <- ll_name
  # reference_list <- ref_list
  # data_dict <- dd_mat

  score1_case_df <- data.frame()

  for (nr in names(reference_list)) {

    reference <- reference_list[[nr]]

    s1_case_vec <- rep(0, nrow(linelist))
    sum_weights_case <- rep(0, nrow(linelist))

    for (nv in data_dict[,'name']) {

      type <- data_dict[[nv,'type']]
      weight <- reference[[nv,'weight']]
      ref_obs <- reference[[nv,'observations']]

      if (!anyNA(ref_obs) & weight != 0) {
        for (i in 1:nrow(linelist)) {

          case_obs <- linelist[[i,nv]]
          if(anyNA(case_obs) | (type == 'int_categorical' & length(case_obs) == 1 & '0' %in% case_obs)) {
            is_in_refobs <- 0.5
          } else if (type %in% c('float', 'int_ordinal', 'date')) {
            is_in_refobs <- any(case_obs >= min(ref_obs) & case_obs <= max(ref_obs))
          } else {
            is_in_refobs <- any(case_obs %in% ref_obs)
          }
          s1_case_vec[i] <- s1_case_vec[i] + weight * as.numeric(is_in_refobs)
          sum_weights_case[i] <- sum_weights_case[i] + weight
        }
      }

    }
    s1_case_vec <- s1_case_vec / sum_weights_case
    s1 <- mean(s1_case_vec)

    score1_case_df <- score1_case_df %>%
      rbind(data.frame(linelist = linelist_name, reference = nr, case_id = rownames(linelist), s1 = s1_case_vec))

  }

  return(score1_case_df)
}
