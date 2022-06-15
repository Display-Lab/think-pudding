library(dplyr, warn.conflicts = FALSE)
library(tidyr, warn.conflicts = FALSE)
library(utils, warn.conflicts = FALSE)
library(rlang, warn.conflicts = FALSE)
library(stats, warn.conflicts = FALSE)
library(lubridate, warn.conflicts = FALSE)

############
# Run Once #
############

# Setup cache is run once per measure-comparator
#  The top level env will include comparator_id and measure_id
setup_cache <- function(data, spek){
  cache <- list()

  # Id column will always be id
  cache$id_colname      <- 'id'
  cache$id_col_sym      <- rlang::sym(cache$id_colname)

  # Hardcode column names.  Extract from spek in subsequent versions.
  cache$denom_colname   <- 'Denominator'
  cache$numer_colname   <- 'Passed_Count'
  cache$time_colname    <- 'Month'
  cache$measure_colname <- 'Measure_Name'

  # Make a symbol of the numerator and denominator columns
  cache$denom_col_sym   <- rlang::sym(cache$denom_colname)
  cache$numer_col_sym   <- rlang::sym(cache$numer_colname)
  cache$time_col_sym    <- rlang::sym(cache$time_colname)
  cache$measure_col_sym <- rlang::sym(cache$measure_colname)

  # Calculate peer average by measure
  cache$measure_id <- measure_id
  cache$comparator_id <- comparator_id
  cache$comparator <- calc_comparator_value(data, spek, measure_id, comparator_id)

  return(cache)
}

calc_comparator_value <- function(data, spek, m_id, c_id){
  if(is.null(c_id)){
    return(NA)
  }else{
    comparator <- spekex::lookup_comparator(c_id, spek)
  }

  val <- spekex::comparison_value_of_comparator(comparator)

  # Assume comparators without values are social comparator.
  if(is.null(val)){
    measure <- spekex::lookup_measure(m_id, spek)
    m_name <- spekex::identifier_of_measure(measure)
    val <- data %>%
      dplyr::filter(Measure_Name == m_name) %>%
      summarize(value=mean(Passed_Count / Denominator)) %>%
      pull(value)
  }

  return(val)
}

####################
# Helper Functions #
####################

# Only pass in time points to be evaluated, as this will check for trend across all points given
eval_positive_trend <- function(x){
  len <- length(x)
  if(len < 2){ return(FALSE) }
  is_tail_ascending <- !is.unsorted(x, strictly=T)
  return(is_tail_ascending)
}

eval_negative_trend <- function(x){
  len <- length(x)
  if(len < 2){ return(FALSE) }
  is_tail_descending <- !is.unsorted(rev(x), strictly=T)
  return(is_tail_descending)
}

# These do not handle a missing most recent time point.  That needs to be handled prior to this call.
# Most recent (greatest) timepoint is at or above comparator and previous point is below
eval_achievement <- function(x, comp){
  if(length(x) < 2){ return(FALSE)}
  bools <- x >= comp
  return( nth(bools, -2) == FALSE & dplyr::nth(bools, -1) == TRUE )
}

eval_loss_content <- function(x, comp){
  if(length(x) < 2){ return(FALSE)}
  bools <- x >= comp
  return( nth(bools, -2) == TRUE & dplyr::nth(bools, -1) == FALSE )
}

eval_consec_neg_gap <- function(x, comp){
  if(length(x) < 2){ return(FALSE) }
  bools <- x < comp
  return( nth(bools, -2) == TRUE & dplyr::nth(bools, -1) == FALSE )
}

eval_consec_pos_gap <- function(x, comp){
  if(length(x) < 2){ return(FALSE) }
  bools <- x > comp
  return( nth(bools, -2) == TRUE & dplyr::nth(bools, -1) == FALSE )
}

########################
# Annotation Functions #
########################

annotate_negative_gap <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  data %>%
    dplyr::filter(!!time == max(!!time)) %>%
    mutate(rate = !!numer / !!denom) %>%
    group_by(!!id) %>%
    summarize(negative_gap = rate < cache$comparator)
}

annotate_positive_gap <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  data %>%
    dplyr::filter(!!time == max(!!time)) %>%
    mutate(rate = !!numer / !!denom) %>%
    group_by(!!id) %>%
    summarize(positive_gap = (rate > cache$comparator))
}

annotate_negative_trend <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  max_month <- as_date(max(data[[time]]))
  min_month <- max_month %m-% months(1)

  data %>%
    dplyr::filter(!!time >= min_month) %>%
    mutate(rate = !!numer / !!denom) %>%
    group_by(!!id) %>%
    summarize(negative_trend = eval_negative_trend(rate))
}

annotate_positive_trend <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  max_month <- as_date(max(data[[time]]))
  min_month <- max_month %m-% months(1)

  data %>%
    dplyr::filter(!!time >= min_month) %>%
    mutate(rate = !!numer / !!denom) %>%
    group_by(!!id) %>%
    summarize(positive_trend = eval_positive_trend(rate))
}

annotate_performance_gap <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  data %>%
    dplyr::filter(!!time == max(!!time)) %>%
    mutate(rate = !!numer / !!denom) %>%
    group_by(!!id) %>%
    summarize(performance_gap = (rate != cache$comparator))
}

annotate_achievement <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  all_ids_df <- data %>% select(!!id) %>% distinct

  elidgibile_ids <- data %>%
    dplyr::filter(!!time == max(!!time)) %>%
    pull(!!id) %>%
    unique

  data %>%
    dplyr::filter(!!id %in% elidgibile_ids) %>%
    mutate(rate = !!numer / !!denom) %>%
    arrange(!!time) %>%
    group_by(!!id) %>%
    summarize( achievement = eval_achievement(rate,cache$comparator)) %>%
    right_join(all_ids_df)
}

annotate_loss_content <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  all_ids_df <- data %>% select(!!id) %>% distinct

  elidgibile_ids <- data %>%
    dplyr::filter(!!time == max(!!time)) %>%
    pull(!!id) %>%
    unique

  data %>%
    dplyr::filter(!!id %in% elidgibile_ids) %>%
    mutate(rate = !!numer / !!denom) %>%
    arrange(!!time) %>%
    group_by(!!id) %>%
    summarize( loss_content = eval_loss_content(rate, cache$comparator)) %>%
    right_join(all_ids_df)
}

annotate_comparators <- function(data, spek){
  # comparator_id provided by running environment. Resides in cache.
  if(is.null(cache$comparator_id)){
    return(NULL)
  }

  comp_type <- spekex::type_of_comparator( spekex::lookup_comparator(cache$comparator_id, spek))

  is_std <- identical(spekex::SE$STANDARD_COMPARATOR_IRI, comp_type)
  is_soc <- identical(spekex::SE$SOCIAL_COMPARATOR_IRI, comp_type)
  is_gol <- identical(spekex::SE$GOAL_COMPARATOR_IRI, comp_type)

  id <- cache$id_col_sym

  # Do three annotations at once.
  data %>% group_by(!!id) %>% summarize(standard_comparator = is_std,
                                        social_comparator = is_soc,
                                        goal_comparator = is_gol)
}

annotate_consec_neg_gap <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  all_ids_df <- data %>% select(!!id) %>% distinct

  elidgibile_ids <- data %>%
    dplyr::filter(!!time == max(!!time)) %>%
    pull(!!id) %>%
    unique

  data %>%
    dplyr::filter(!!id %in% elidgibile_ids) %>%
    mutate(rate = !!numer / !!denom) %>%
    arrange(!!time) %>%
    group_by(!!id) %>%
    summarize( consec_neg_gap = eval_consec_neg_gap(rate, cache$comparator)) %>%
    right_join(all_ids_df)
}

annotate_consec_pos_gap <- function(data, spek){
  time <- cache$time_col_sym
  denom <- cache$denom_col_sym
  numer <- cache$numer_col_sym
  id <- cache$id_col_sym

  all_ids_df <- data %>% select(!!id) %>% distinct

  elidgibile_ids <- data %>%
    dplyr::filter(!!time == max(!!time)) %>%
    pull(!!id) %>%
    unique

  data %>%
    dplyr::filter(!!id %in% elidgibile_ids) %>%
    mutate(rate = !!numer / !!denom) %>%
    arrange(!!time) %>%
    group_by(!!id) %>%
    summarize( consec_pos_gap = eval_consec_pos_gap(rate, cache$comparator)) %>%
    right_join(all_ids_df)
}
