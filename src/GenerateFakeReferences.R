GenerateFakeReferences <- function(data_dict, ref_names, min_relative_ext, max_extension_date) {

  # Generates random fake references with names ref_names. For reproducibility, the random
  # seed is set for each reference.
  # Takes data_dict as input, the data dictionary formated as a matrix of lists.
  # It returns a list of referencres, each formated as a matrix of lists.

  reference_list <- list()

  for (k in 1:length(ref_names)) {

    set.seed(k)

    reference <- matrix(list(), nrow=dim(data_dict)[1], ncol=4)
    rownames(reference) <- rownames(data_dict)
    colnames(reference) <- c('name','weight','observations','extension')

    weight_vec <- sample(c(rep(0, round(dim(data_dict)[1]/4)),
      rep(0.5, round(dim(data_dict)[1]/2)),
      rep(1, dim(data_dict)[1] - round(dim(data_dict)[1]/4) -
          round(dim(data_dict)[1]/2))))

    for (i in 1:dim(data_dict)[1]) {

      reference[[i,'name']] <- data_dict[[i,'name']]

      reference[[i,'weight']] <- weight_vec[i]

      type <- data_dict[[i,'type']]
      if (type == 'int_categorical') {

        values <- names(data_dict[[i,'values']])
        values <- values[values != '0']
        n_values <- sample(1:max(1,(length(values)-1)), 1)
        reference[[i,'observations']] <- sort(sample(values, n_values, replace = F))
        reference[[i,'extension']] <- NA

      } else if (type == 'int_ordinal') {

        min_value_dd <- min(data_dict[[i,'values']])
        max_value_dd <- max(data_dict[[i,'values']])
        min_max_values <- sort(sample(seq(min_value_dd,max_value_dd), 2, replace=F))
        reference[[i,'observations']] <- min_max_values
        reference[[i,'extension']] <- sample(1:max(1, min_max_values[2]-min_max_values[1]), 1)

      } else if (type == 'float') {

        min_value_dd <- min(data_dict[[i,'values']])
        max_value_dd <- max(data_dict[[i,'values']])
        min_max_values <- sort(runif(2, min=min_value_dd, max=max_value_dd))
        reference[[i,'observations']] <- min_max_values
        reference[[i,'extension']] <- runif(1, min=min_relative_ext*(min_max_values[2]-min_max_values[1]),
          max=min_max_values[2]-min_max_values[1])

      } else if (type == 'date') {

        reference[[i,'observations']] <- NA
        reference[[i,'extension']] <- sample(1:max_extension_date, 1)

      }

    }

    reference_list[[ref_names[k]]] <- reference
  }

  return(reference_list)

}
