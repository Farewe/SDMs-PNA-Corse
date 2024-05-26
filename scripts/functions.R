simplify_species_name <- function(x)
{
  x <- strsplit(x,
                split = " ")
  sapply(x, function(y) {
    paste(y[1:2], collapse = " ")
  }
  )
}
