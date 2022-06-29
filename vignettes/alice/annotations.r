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
  cache$rate_colname   <- 'rate'
  cache$time_colname   <- 'time'
  cache$measure_colname <- 'measure'

  # Make a symbol of the  columns
  cache$rate_col_sym    <- rlang::sym(cache$rate_colname)
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
    val <- data %>%
      summarize(value=mean(rate)) %>%
      pull(value)
  }

  return(val)
}

########################
# Annotation Functions #
########################

annotate_positive_gap <- function(data, spek){
  rate <- cache$rate_col_sym
  time <- cache$time_col_sym
  id <- cache$id_col_sym

  data %>%
    dplyr::filter(!!time == max(!!time)) %>%
    group_by(!!id) %>%
    summarize(positive_gap = (!!rate > cache$comparator))
}

annotate_comparators <- function(data, spek){
  # comparator_id provided by running environment. Resides in cache.
  cache$comparator_id
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
