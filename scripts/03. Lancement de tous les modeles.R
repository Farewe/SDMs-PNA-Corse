files <- c(
  "SDMs_amphibiens_v2.Rmd",
  "SDMs_chiropteres_cavernicoles_g1_v2.Rmd",
  "SDMs_chiropteres_forestiers_v2.Rmd",
  "SDMs_chiropteres_zoneshumides_v2.Rmd",
  "SDMs_serpentinites_v2.Rmd",
  "SDMs_libellules_v2.Rmd",
  "SDMs_papillons_v2.Rmd",
  "SDMs_sittelle_v2.Rmd"
  )
  
for (f in files) {
  cat(paste0(Sys.time()),
      " - fichier ", f, "\n")
   run <- try(rmarkdown::render(f))
   if (inherits(run, "try-error")) {
     cat(paste0(Sys.time()), "\n",
         "File ", f, " failed")
   }
}