# order_by

# order_by defines the chronological order in which fields are seen
order_by <- function(id_field,impute_method=c('BEST_FIT','ONE_MISSING','ADD_MISSING','NONE')) {
  av_state$order_by <<- id_field
  impute_method <- match.arg(impute_method)
  i <- 0
  for (data_frame in av_state$data) {
    i <- i+1
    used_impute_method <- impute_method
    if (impute_method == 'BEST_FIT') {
      used_impute_method <- determine_impute_method(id_field,data_frame)
    }
    order_method <- switch(used_impute_method,
      ONE_MISSING = order_by_impute_one_missing,
      ADD_MISSING = order_by_impute_add_missing,
      NONE = order_by_impute_none
    )
    missing_before <- calc_missing(av_state$data[[i]])
    av_state$data[[i]] <<- order_method(id_field,data_frame)
    missing_after <- calc_missing(av_state$data[[i]])
    if (missing_before != missing_after) {
      cat(paste("order_by: missing values went from",missing_before,"to",missing_after,"for subset",i,"\n"))
    }
  }
}

determine_impute_method <- function(id_field,data_frame) {
  if (can_do_one_missing(id_field,data_frame)) {
    'ONE_MISSING'
  } else if (can_do_add_missing(id_field,data_frame

}
can_do_one_missing <- function(id_field,data_frame) {
  any(is.na(getElement(data_frame,id_field))) &&
  sum(is.na(getElement(data_frame,id_field))) == 1 &&
  !is.null(missing_in_range(data_frame[[id_field]]),no_warn = TRUE)
}
can_do_add_missing <- function(id_field,data_frame) {
  !any(is.na(data_frame[[id_field]]))
}

order_by_impute_one_missing <- function(id_field,data_frame) {
  if (any(is.na(getElement(data_frame,id_field)))) {
    if (sum(is.na(getElement(data_frame,id_field))) != 1) {
      stop("More than one field is NA")
    }
    imputed_val <- missing_in_range(getElement(data_frame,id_field))
    if (!is.null(imputed_val)) {
      cat("order_by_impute_one_missing imputed",imputed_val,"for one row of",frame_identifier(data_frame),"\n")
      data_frame[is.na(getElement(data_frame,id_field)),][[id_field]] <- imputed_val
    }
  }
  data_frame[with(data_frame, order(getElement(data_frame,id_field))), ]
}

frame_identifier <- function(data_frame) {
  if (is.null(av_state[['group_by']])) {
    ""
  } else {
    id_field <- av_state[['group_by']]
    paste(id_field,' = ',data_frame[[id_field]][1],sep='')
  }
}

missing_in_range <- function(sorting_column, no_warn = FALSE) {
  ordered_column <- sort(sorting_column)
  mmin <- min(ordered_column)
  mmax <- max(ordered_column)
  diffs <- ordered_column[2:length(ordered_column)]-ordered_column[1:length(ordered_column)-1]
  tab <- table(diffs)
  if (length(order(tab)) == 1) {
    mmax+1
  } else {
    infreq <- order(tab)[[1]]
    freq <- order(tab)[[2]]
    idx <- which(diffs == infreq)
    if (length(idx) == 0) {
      if (!no_warn) { warning("could not determine a valid substitute for the NA value") }
      NULL
    } else {
      ordered_column[idx]+freq
    }
  }
}

order_by_impute_none <- function(id_field,data_frame) {
  sorting_column <- getElement(data_frame,id_field)
  if (any(is.na(sorting_column))) {
    warning(paste("Some rows have an NA value for the sorting attribute,",id_field))
  }
  data_frame[with(data_frame, order(sorting_column)), ]
}

order_by_impute_add_missing <- function(id_field,data_frame) {
  sorting_column <- getElement(data_frame,id_field)
  if (any(is.na(sorting_column))) {
    halt(paste("Some fields are NA, they need to be assigned an",
               id_field,"before we can determine which rows are missing."))
  }
  ordered_column <- sort(sorting_column)
  mmin <- min(ordered_column)
  mmax <- max(ordered_column)
  gbv <- NULL
  if (!is.null(av_state$group_by)) {
    gbv <- data_frame[1,][[av_state$group_by]]
  }
  for(i in mmin:mmax) {
    if (!any(sorting_column == i)) {
      cat(paste("order_by: adding a row with",id_field,"=",i,"\n"))
      data_frame <- rbind(data_frame,rep(NA,times=dim(data_frame)[[2]]))
      data_frame[dim(data_frame)[[1]],][[id_field]] <- i
      if (!is.null(av_state$group_by)) {
        data_frame[dim(data_frame)[[1]],][[av_state$group_by]] <- gbv
      }
    }
  }
  data_frame[with(data_frame, order(getElement(data_frame,id_field))), ]
}

determine_input_method <- function(id_field) {
  


  'NONE'
}

#print(order_by_impute_add_missing('tijdstip',data.frame(id=rep(1,times=5),tijdstip=c(1,3,5,6,7),home=6:10)))
