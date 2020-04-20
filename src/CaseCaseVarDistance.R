CaseCaseVarDistance <- function (case1, case2, variable, var_type) {

  val1 <- case1[[variable]]
  val2 <- case2[[variable]]
  if (any(c(anyNA(val1),anyNA(val2)))) {
    distance <- NA
  } else {
    if (var_type=='int_categorical') {
      distance <- 1-as.numeric(any(val1 %in% val2))
    } else {
      distance_vec <- c()
      for (i in 1:length(val1)) {
        for (j in 1:length(val2)) {
          distance_vec <- c(distance_vec,abs(as.numeric(val1[i])-as.numeric(val2[j])))
        }
      }
      distance <- min(distance_vec)
    }
  }
  return(distance)

}
