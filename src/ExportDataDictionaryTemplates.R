ExportDataDictionaryTemplates <- function(data_dictionary_redux, datadictionary_dir, reference_dir,
  linelist_dir) {

  # Exports data dictionary, a reference template and/or a line-list template to CSV.
  # Set target directory to NULL if you don't want to export one of those.

  # Data dictionary
  if (!is.null(datadictionary_dir)) {
    write.csv(data_dictionary_redux, file=paste0(datadictionary_dir, '/data_dictionary_redux.csv'),
      row.names=F)
  }

  # The reference template is the same with supplementary columns "weight", "observations" and "extension",
  # which are empty in the template
  if (!is.null(reference_dir)) {
    reference_template <- cbind(data_dictionary_redux,
      data.frame(weight=NA, observations=NA, extension=NA))
    write.csv(reference_template, file=paste0(reference_dir, '/reference_template.csv'), row.names = F)
  }
  # Line list has "case_id" and the variables of the data dictionary as columns, each row is a case
  if (!is.null(linelist_dir)) {
    linelist_template <- data.frame(case_id = c('case1','case2','case3'))
    for (i in 1:nrow(data_dictionary_redux)) {
      linelist_template <- cbind(linelist_template, rep(NA,3))
    }
    names(linelist_template) <- c('case_id',data_dictionary_redux$name)
    write.csv(linelist_template, file=paste0(linelist_dir, '/linelist_template.csv'), row.names = F)
  }

}
