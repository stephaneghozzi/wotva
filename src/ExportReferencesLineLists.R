ExportReferencesLineLists <- function(ref_ll_list, ref_ll_dir) {

  # Save list of references or list of line lists to CSVs, one file per reference or line list.

  id_var <- 'id'

  for (nr in names(ref_ll_list)) {
    ref_ll <- ref_ll_list[[nr]]
    ref_ll_df <- data.frame(name=rownames(ref_ll))
    if ('name' %in% colnames(ref_ll)) {
      id_var <- 'name'
    } else if ('case_id' %in% colnames(ref_ll)) {
      id_var <- 'case_id'
    }
    col_names <- colnames(ref_ll)[colnames(ref_ll)!=id_var]
    for (cn in col_names) {
      ref_ll_df <- cbind(ref_ll_df, sapply(1:nrow(ref_ll),
        function (i) paste(ref_ll[i,cn][[1]], collapse = ', ')))
    }
    names(ref_ll_df) <- c(id_var,col_names)
    write.csv(ref_ll_df, file=paste0(ref_ll_dir, '/', paste0(gsub(' ','_',nr), '.csv')),
      row.names=F)
  }

}
