GenerateEventLineList <- function (data_dict, list_of_refs, noise, n_cases, max_mult, ci_ext, ll_id,
  date_from, date_to) {

  ref_list <- list_of_refs
  available_dates <- seq(date_from, date_to, by = 'day')

  linelist <- matrix(list(), nrow = n_cases, ncol = 1+nrow(data_dict))
  colnames(linelist) <- c('case_id', rownames(data_dict))
  rownames(linelist) <- sapply(1:n_cases,
    function (i) paste0(ll_id, '_', paste(rep(0, floor(log10(n_cases))-floor(log10(i))), collapse=''), i))

  # Set the lower and upper bound defining the observations within the extension
  if (!is.null(ref_list) & noise != 1) {
    for (k in 1:length(ref_list)) {
      extension_observations <- matrix(list(), nrow = nrow(data_dict), ncol = 1)
      rownames(extension_observations) <- rownames(data_dict)
      colnames(extension_observations) <- 'observations_in_ext'
      for (j_oe in 1:nrow(data_dict)) {
        type <- data_dict[[j_oe,'type']]
        observations <- ref_list[[k]][[j_oe,'observations']]
        if (type == 'date') {
          observations <- available_dates
        } else if (type == 'int_ordinal' & !anyNA(observations)) {
          observations <- seq(min(observations), max(observations))
        }
        extension <- ref_list[[k]][[j_oe,'extension']]
        if (!is.na(extension)) {
          if (type == 'float') {
            lower_bound <- runif(1,min=min(observations),max=max(observations)-extension)
            upper_bound <- lower_bound+extension
            extension_observations[[j_oe,'observations_in_ext']] <- c(lower_bound,upper_bound)
          } else {
            if (max(observations) == min(observations)+extension) {
              lower_bound <- min(observations)
              upper_bound <- max(observations)
            } else {
              lower_bound <- sample(observations[observations <= max(observations)-extension], 1)
              upper_bound <- max(observations[observations <= lower_bound+extension])
            }
            extension_observations[[j_oe,'observations_in_ext']] <-
              observations[observations >= lower_bound & observations <= upper_bound]

          }
        } else {
          extension_observations[[j_oe,'observations_in_ext']] <- observations
        }
      }
      ref_list[[k]] <- cbind(ref_list[[k]], extension_observations)
    }
  }

  for (i in 1:n_cases) {

    linelist[[i,'case_id']] <- paste0(ll_id, '_', i)

    # Choose which reference the ith case is drawn from
    if (is.null(ref_list) | noise == 1) {
      reference <- NULL
    } else {
      which_ref <- ceiling(i*length(ref_list)/n_cases)
      reference <- ref_list[[which_ref]]
    }

    for (j in 1:nrow(data_dict)) {

      type <- data_dict[[j,'type']]
      multiplicity <- data_dict[[j,'multiplicity']]

      # Choose whether, for the ith case, the observations of the jth variable are drawn from the data
      # dictionary or from the reference
      draw_var_from_data_dictionary <- sample(0:1, 1, prob = c(1-noise, noise))
      if (is.null(reference)) {
        draw_var_from_data_dictionary <- 1
      } else if (anyNA(reference[[j,'observations']])) {
        draw_var_from_data_dictionary <- 1
      }
      if (draw_var_from_data_dictionary == 1) {
        observations <- data_dict[[j,'values']]
        if (type == 'int_categorical') {
          observations <- names(observations)
        } else if (type == 'date') {
          observations <- available_dates
        } else if (type == 'int_ordinal') {
          observations <- seq(min(observations), max(observations))
        }
        observations_in_ext <- observations
      } else {
        observations <- reference[[j,'observations']]
        if (type == 'date') {
          observations <- available_dates
        } else if (type == 'int_ordinal') {
          observations <- seq(min(observations), max(observations))
        } else if (type == 'int_categorical') {
          # Don't accept answer "0" (unknown) for categorical variables
          observations <- observations[observations!='0']
        }
        observations_in_ext <- reference[[j,'observations_in_ext']]
      }

      # Set number of answers
      if (type == 'float') {
        mult_val_max <- max_mult
      } else {
        mult_val_max <- min(max_mult, length(observations))
      }

      if (multiplicity == 0) {
        mult_val <- 1
      } else {
        mult_val <- sample(1:mult_val_max, 1)
      }

      # Draw random observations
      if (type == 'int_categorical') {
        first_val <- sample(1:length(observations), 1)
        if (observations[first_val] == '0' | mult_val == 1) {
          var_val <- observations[first_val]
        } else {
          other_val <- 1:length(observations[observations!='0'])
          other_val <- other_val[other_val!= first_val]
          which_val <- sort(c(first_val, sample(other_val, mult_val-1)))
          var_val <- observations[which_val]
        }
      } else if (type == 'float') {
        var_val <- c()
        for (m in 1:mult_val) {
          in_extension <- sample(0:1,1,prob=c(1-ci_ext,ci_ext))
          if (in_extension | identical(observations,observations_in_ext)) {
            val <- runif(1, min = min(observations_in_ext), max = max(observations_in_ext))
          } else {
            val1 <- runif(1, min = min(observations), max = min(observations_in_ext))
            val2 <- runif(1, min = max(observations_in_ext), max = max(observations))
            val <- sample(c(val1,val2), 1,
              prob = c(min(observations_in_ext)-min(observations),
                max(observations)-max(observations_in_ext)) /
                  (min(observations_in_ext)-min(observations)+max(observations)-max(observations_in_ext)))
          }
          var_val <- c(var_val, val)
        }
        var_val <- sort(var_val)
      } else {
        var_val <- c()
        val_in_ext_current <- observations_in_ext
        val_out_ext_current <- observations[!observations %in% observations_in_ext]
        m <- mult_val
        while (m > 0) {
          in_extension <- sample(0:1,1,prob=c(1-ci_ext,ci_ext))
          if (identical(observations,observations_in_ext)) {
            in_extension <- 1
          }
          if (in_extension & length(val_in_ext_current) > 0) {
            val <- sample(val_in_ext_current, 1)
            val_in_ext_current <- val_in_ext_current[val_in_ext_current != val]
            var_val <- c(var_val, val)
            m <- m-1
          } else if (!in_extension & length(val_out_ext_current) > 0){
            val <- sample(val_out_ext_current, 1)
            val_out_ext_current <- val_out_ext_current[val_out_ext_current != val]
            var_val <- c(var_val, val)
            m <- m-1
          } else {
            m <- 0
          }
        }
        var_val <- sort(var_val)
        if (type == 'date') {
          var_val <- as.Date(var_val, origin = '1970-01-01')
        }
      }

      linelist[[i,data_dict[[j,'name']]]] <- var_val
    }
  }

  return(linelist)
}
