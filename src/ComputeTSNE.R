ComputeTSNE <- function(dist_mat, linelist, linelist_name, reference_list, n_ref_cases) {

  # Computes the t-SNE projection of cases in linelist based on the distance matrix dist_mat.
  # WARNING: it assumes reference cases (n_ref_cases for each reference) at the beginning of the distance
  # matrix.
  # linelist can be either a matrix of lists or a data frame.

    cases_reduced_tsne <- Rtsne(dist_mat,is_distance=T,theta=0,perplexity=(nrow(dist_mat)-1)/3-1)
    tsne_dist_projection <- data.frame(x=cases_reduced_tsne$Y[,1],y=cases_reduced_tsne$Y[,2],
      reference = c(sapply(names(reference_list), function (nr) rep(nr,n_ref_cases)),
        rep(linelist_name, nrow(linelist))), case_id = rownames(dist_mat))

    return(tsne_dist_projection)
}
