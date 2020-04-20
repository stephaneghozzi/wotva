ProcessDataDictionary <- function(datadictionary_dir) {

  # Reads and processes the data dictionary "dictionnary complet 04062019.xlsx"
  # It is very much tailor made for that particular file, hence no arguments to the function besides the
  # path.

  data_dictionary_raw <- read_xlsx(paste0(datadictionary_dir, '/dictionnary complet 04062019.xlsx'),
    sheet = 'Architecture') %>% mutate(i_line = as.integer(row_number() + 1)) %>%
    select(i_line, everything())

  data_dictionary_redux <- data_dictionary_raw %>% cbind(data.frame(type = 'TBD', format = 'TBD',
    values = 'TBD', multiplicity = 0L, stringsAsFactors = F))

  # 1. Keep only variables in T0 or T1
  data_dictionary_redux <- data_dictionary_redux %>% filter(T0 == 1 | T1 == 1)

  # 2. Manage duplicates
  data_dictionary_redux <- data_dictionary_redux %>% mutate(name = ifelse(is.na(`Variable short name`),
    tolower(`Short label`), tolower(`Variable short name`)))

  data_dictionary_redux <- data_dictionary_redux %>% group_by(name) %>%
    mutate(mult_dupl = n()) %>% ungroup()

  for (nn in data_dictionary_redux %>% filter(mult_dupl > 1) %>% pull(name) %>% unique()) {
    i_keep <- NA
    i_T0T1 <- data_dictionary_redux %>% filter(name == nn & T0 == 1 & T1 == 1) %>% pull(i_line)
    i_notT0_T1 <- data_dictionary_redux %>% filter(name == nn & is.na(T0) & T1 == 1) %>% pull(i_line)
    i_T0_notT1 <- data_dictionary_redux %>% filter(name == nn & T0 == 1 & is.na(T1)) %>% pull(i_line)
    if (length(i_T0T1) == 1) {
      i_keep <- i_T0T1
    } else if (length(i_notT0_T1) == 1) {
      i_keep <- i_notT0_T1
    } else if (length(i_T0_notT1) == 1) {
      i_keep <- i_T0_notT1
    } else {
      stop('Encountered a duplicates issue that I don\'t know how to solve!\ni_T0T1 = ', i_T0T1,
        ', i_notT0_T1 = ', i_notT0_T1, ', i_T0_notT1 = ', i_T0_notT1)
    }
    data_dictionary_redux <- data_dictionary_redux %>% filter(name != nn | name == nn & i_line == i_keep)
  }

  # # 3. Standardize names
  data_dictionary_redux <- data_dictionary_redux %>% mutate(name = gsub('[^[:alnum:]_]', '_', tolower(name)))

  # 4. Types and formats
  # string
  i_line_string <- data_dictionary_redux %>% filter((any(str_detect(`Data type`, regex(c('string','text'),
    ignore_case = T))) & !is.na(`Data type`)) | (any(str_detect(Format, regex('text',ignore_case = T)) &
      !is.na(Format)))) %>% pull(i_line)

  data_dictionary_redux <- data_dictionary_redux %>% mutate(type = replace(type, i_line %in% i_line_string,
    'string'), format = replace(format, i_line %in% i_line_string, NA))

  # int_categorical
  i_line_binary <- data_dictionary_redux %>%
    filter(substr(`Permissible values (response options)`,1,7) %in% c('0 = Yes','1 = Yes','2 = Yes')) %>%
    pull(i_line)

  i_line_int_categorical <- data_dictionary_redux %>%
    filter(`Data type` %in% c('Numeric, Single choice category.', 'Numeric. Multiple choice categories',
      'Numeric. Single choice categories', 'Numeric. Single choice category.') |
        (`Data type` %in% c('N', 'Number', 'Numeric') | Format %in% c('N', 'Number', 'Numeric')) &
        (grepl('=', Format) | grepl('=', `Permissible values (response options)`)) &
        !name %in% c('sign_syst','sign_temp') |
        name %in% c('postcode', 'sign_bleed_site', 'telephone_number') |
        i_line %in% i_line_binary) %>% pull(i_line)

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(type = replace(type, i_line %in% i_line_int_categorical, 'int_categorical'),
      format = replace(format, i_line %in% i_line_int_categorical, NA))

  # int_ordinal
  i_line_int_ordinal <- data_dictionary_redux %>% filter(!is.na(name) &
      name %in% c('age_year', 'age_month', 'no_hhd', 'sign_rash_duration')) %>% pull(i_line)

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(type = replace(type, i_line %in% i_line_int_ordinal, 'int_ordinal'),
      format = replace(format, i_line %in% i_line_int_ordinal, NA))

  # float
  i_line_float <- data_dictionary_redux %>% filter(grepl('#', `Permissible values (response options)`) |
      name %in% c('cond_malnut', 'gps_lat', 'gps_long', 'sign_syst', 'sign_temp', 'sign_dias') |
      grepl('/L)', `Short label`)) %>% pull(i_line)

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(type = replace(type, i_line %in% i_line_float, 'float'),
      format = replace(format, i_line %in% i_line_float, "point_decimal_no_grouping"))

  # date
  i_line_date <- data_dictionary_redux %>% filter((grepl('date', name, ignore.case = T) |
      grepl('date', `Short label`, ignore.case = T) | grepl('date', Description, ignore.case = T) |
      grepl('date', `Data type`, ignore.case = T) |  `Data type` == 'DD/MM/YYYY' |
      Format %in% c('DD/MM/YYYY', 'DD.MM.YYYY')) & !name %in% c('age_year', 'outcome',
        'atb_before', 'atb_treatment', 'cond_partum')) %>% pull(i_line)

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(type = replace(type, i_line %in% i_line_date, 'date'),
      format = replace(format, i_line %in% i_line_date, 'YYYY-MM-DD'))

  # 5. Permissible values
  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(values = ifelse(name %in% c('age_month', 'age_year', 'no_hhd'),
      gsub('-', ', ', gsub(' ', '', `Permissible values (response options)`)), values))

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(values = replace(values, name == 'sign_bleed_site',
      '1=gums;2=mouth;3=nose;4=vomit;5=stool;6=urine;7=vagina;8=injectionsites'))

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(values = replace(values, name == 'sick_comm_relat',
      '1=friend;2=workmate;3=relative;4=romanticpartner'))

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(values = ifelse(name %in% c('animal_dom_type', 'sex', 'onset_type', 'sign_rash_type',
      'vac_source', 'water_drinking_qual', 'notification_facility_type', 'outcome', 'classification'),
      gsub('[[:punct:]]$', '', gsub('[^[:alnum:];=]', '',
        gsub(',', ';', tolower(`Permissible values (response options)`)))), values))

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(values = ifelse(name %in% c('test1_result', 'sample3_quality'),
      gsub('[[:punct:]]$', '', gsub('[^[:alnum:];=]', '', gsub(',', ';', tolower(Format)))), values))

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(values = replace(values, i_line %in% i_line_binary, '0=unknown;1=yes;2=no'))

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(values = ifelse(grepl('9=', values), paste0('0=unknown;', values), values))

  for (il in data_dictionary_redux %>% filter(grepl('9=', values)) %>% pull(i_line)) {
    val <- data_dictionary_redux$values[data_dictionary_redux$i_line == il]
    val <- paste(strsplit(val, ';')[[1]][substr(strsplit(val,';')[[1]], 1, 1) != '9'], collapse = ';')
    val <- paste(strsplit(val, ';')[[1]][order(substr(strsplit(val,';')[[1]], 1, 1))], collapse = ';')
    data_dictionary_redux$values[data_dictionary_redux$i_line == il] <- val
  }

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name %in% c('gps_lat', 'gps_long'), '-180, 180'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name %in% c('alt_sgpt__u_l_', 'ast_sgo__u_l_'), '1, 2000'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'lactate__mmol_l_', '0, 3'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'haemoglobin___g_l_', '60, 180'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'creatinine__umol_l_', '50, 300'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'total_bilirubin__umol_l_', '0, 99'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'potassium__mmol_l_', '0, 10'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'wbc_count__x109_l_', '4, 20'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'urea__mmol_l_', '0, 3'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'platelets__x109_l_', '20, 500'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'creatinine_kinase__u_l_', '10, 500'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'sign_temp', '24, 44'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'sign_hr', '40, 160'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'sign_syst', '5, 25'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'sign_dias', '2, 13'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'sign_resprate', '8, 30'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'sign_sat', '65, 100'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    name == 'cond_malnut', '80, 500'))

  data_dictionary_redux <- data_dictionary_redux %>% mutate(values = replace(values,
    i_line %in% i_line_date, NA))

  # 6. Multiplicities
  i_line_multiplicity <- data_dictionary_redux %>%
    filter(grepl('multiple', `Number of answers`, ignore.case = T) & !name %in%
        c('animal_dom_type', 'animal_sick_type', 'animal_sick_sign', 'food_change', 'food_unusual')) %>%
    pull(i_line)

  data_dictionary_redux <- data_dictionary_redux %>%
    mutate(multiplicity = replace(multiplicity, i_line %in% i_line_multiplicity, 1L))

  # Keep only columns useful for visual inspection or for subsequent analysis, rename variables
  data_dictionary_redux <- data_dictionary_redux %>% mutate(module = Module, subcategory = `Sub-category`,
    label = `Short label`, description = Description) %>% select(i_line, name, type, format, values,
      multiplicity, module, subcategory, label, description)

  data_dictionary_redux <- data_dictionary_redux[,
    c('name', 'label', 'type', 'format', 'values', 'multiplicity')]

  # Discard variables for which the type is unknown, are not useful or are redundant
  data_dictionary_redux <- data_dictionary_redux[-which(data_dictionary_redux$type=='TBD' |
    data_dictionary_redux$values=='TBD' |
    data_dictionary_redux$name %in% c('age_month', 'interview_date', 'telephone_number',
    'test1_result', 'classification')),]

  return(data_dictionary_redux)

}
