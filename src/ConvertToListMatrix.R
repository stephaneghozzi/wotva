ConvertToListMatrix <- function(df, data_dict, data_type) {
  # Takes a data dictionary, reference or line list, e.g. as imported from CSV,
  # and converts it to a matrix of lists.
  # For the data dictionary set data_dict = NULL.

  mat <- matrix(list(), nrow = nrow(df), ncol = ncol(df))
  colnames(mat) <- names(df)

  if (data_type=='datadictionary') {

    rownames(mat) <- df$name

    for (i in 1:nrow(df)) {
      for (j in 1:ncol(df)) {
        dd_entry <- df[i,j][[1]]
        if (df$type[i] == 'int_categorical' & names(df)[j] == 'values' &
            grepl('=',dd_entry)) {
          categories_list <- list()
          for (ca in strsplit(dd_entry, ';')[[1]]) {
            categories_list[[strsplit(ca, '=')[[1]][1]]] <- strsplit(ca, '=')[[1]][2]
          }
          mat[[i,j]] <- categories_list
        } else if (df$type[i] %in% c('float','int_ordinal') &
            names(df)[j] == 'values' & grepl(', ',dd_entry)) {
          mat[[i,j]] <- as.numeric(strsplit(dd_entry,', ')[[1]])
        } else {
          mat[[i,j]] <- dd_entry
        }
      }
    }

  } else if (data_type=='reference') {

    if (!all(df$name %in% rownames(data_dict))) {
      stop('In ConvertToListMatrix: Reference has variables not in the data dictionary!')
    }

    rownames(mat) <- df$name

    for (i in 1:nrow(df)) {
      mat[[i,'name']] <- df$name[i]
      # For weights missing value is interpreted as 0
      mat[[i,'weight']] <- ifelse(is.na(df$weight[i]),0,df$weight[i])
      if (is.na(df$observations[i])) {
        mat[[i,'observations']] <- NA
      } else {
        mat[[i,'observations']] <- strsplit(gsub(' ', '', df$observations[i]), ',')[[1]]
        type <- data_dict[df$name[i],'type'][[1]]
        if (type == 'float') {
          mat[[i,'observations']] <- as.numeric(mat[[i,'observations']])
        } else if (type == 'int_ordinal') {
          mat[[i,'observations']] <- as.integer(mat[[i,'observations']])
        } else if (type == 'date') {
          mat[[i,'observations']] <- as.Date(mat[[i,'observations']])
        }
      }
      mat[[i,'extension']] <- df$extension[i]
    }

  } else if (data_type=='linelist') {

    if (!all(names(df)[names(df)!='case_id'] %in% rownames(data_dict))) {
      stop('In ConvertToListMatrix: Line list has variables not in the data dictionary!')
    }
    rownames(mat) <- df$case_id
    colnames(mat) <- names(df)

    for (i in 1:nrow(df)) {
      for (j in 1:ncol(df)) {
        if (is.na(df[i,j])) {
          mat[[i,j]] <- NA
        } else {
          mat[[i,j]] <- strsplit(gsub(' ', '', df[i,j]), ',')[[1]]
          if (names(df)[j] == 'case_id') {
            type <- 'case_id'
          } else {
            type <- data_dict[names(df)[j],'type'][[1]]
          }
          if (type == 'float') {
            mat[[i,j]] <- as.numeric(mat[[i,j]])
          } else if (type == 'int_ordinal') {
            mat[[i,j]] <- as.integer(mat[[i,j]])
          } else if (type == 'date') {
            mat[[i,j]] <- as.Date(mat[[i,j]])
          }
        }
      }
    }

  } else {

    stop('In ConvertToListMatrix: wrong data_type!')

  }

  return(mat)
}
