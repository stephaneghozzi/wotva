ComputeDistances <- function (linelist, reference_list, data_dict, with_progress) {

  av_weights <- sapply(data_dict[,'name'], function (nv)
    mean(sapply(names(reference_list), function (nr) reference_list[[nr]][[nv,'weight']])))
  names(av_weights) <- data_dict[,'name']

  dist_mat_init <- matrix(0,nrow=nrow(linelist),ncol=nrow(linelist))
  rownames(dist_mat_init) <- linelist[,'case_id']
  colnames(dist_mat_init) <- linelist[,'case_id']
  dist_mat <- dist_mat_init

  prog <- 0
  n_operations <- ncol(linelist)-1

  for (nv in colnames(linelist)[colnames(linelist)!='case_id']) {

    if (with_progress) {
      prog <- prog+1
      incProgress(1/n_operations, detail=paste0(round(100*prog/n_operations), '% done'))
    }

    if (av_weights[nv] != 0) {
      dist_mat_var <- dist_mat_init
      if (!all(is.na(linelist[,nv]))) {
        type <- data_dict[[nv,'type']]
        for (i in 2:nrow(dist_mat_var)) {
          case_i <- linelist[i,]
          if (!anyNA(case_i[[nv]])) {
            for (j in 1:(i-1)) {
              case_j <- linelist[j,]
              dist_mat_var[i,j] <- CaseCaseVarDistance(case_i,case_j,nv,type)
            }
          } else {
            dist_mat_var[i,1:(i-1)] <- NA
          }
        }
        t_dist_mat_var <- t(dist_mat_var)
        dist_mat_var[upper.tri(dist_mat_var)] <- t_dist_mat_var[upper.tri(t_dist_mat_var)]
        if (max(dist_mat_var, na.rm = T) > 0) {
          dist_mat_var <- dist_mat_var/max(dist_mat_var,na.rm = T)
        }
        dist_mat_var[is.na(dist_mat_var)] <- 0.5
      } else {
        dist_mat_var <- 0.5
      }
      dist_mat <- dist_mat + av_weights[nv]*(dist_mat_var^2)
    }

  }
  dist_mat <- (dist_mat/sum(av_weights))^0.5

  return(dist_mat)

}
