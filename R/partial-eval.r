#' @examples
#' data("baseball", package = "plyr")
#' bdf <- data_frame_source(baseball)
#' partial_eval(bdf, quote(year > 1980))
#'
#' ids <- c("ansonca01", "forceda01", "mathebo01")
#' partial_eval(bdf, quote(id %in% ids))
#'
#' # You can use remote and local to disambiguate between local and remote
#' # variables: otherwise remote is always preferred
#' year <- 1980
#' partial_eval(bdf, quote(year > year))
#' partial_eval(bdf, quote(remote(year) > local(year)))
#' partial_eval(bdf, quote(year > local(year)))
partial_eval <- function(source, call, env = parent.frame()) {
  if (is.atomic(call)) return(call)

  if (is.symbol(call)) {
    # Symbols must be resolveable either locally or remotely

    name <- as.character(call)
    if (name %in% source_vars(source)) {
      substitute(remote_var(var), list(var = as.character(call)))
    } else if (exists(name, env)) {
      substitute(local_value(x), list(x = get(name, env)))
    } else {
      stop(name, " not defined locally or in data source")
    }
  } else if (is.call(call)) {
    # Process call arguments recursively, unless user has manually called
    # remote_var/local_value
    name <- as.character(call[[1]])
    if (name == "local") {
      substitute(local_value(x), list(x = eval(call[[2]], env)))
    } else if (name == "remote") {
      substitute(remote_var(var), list(var = as.character(call[[2]])))
    } else {
      call[-1] <- lapply(call[-1], partial_eval, source = source, env = env)
      call
    }
  } else {
    stop("Unknown input type: ", class(call))
  }
}