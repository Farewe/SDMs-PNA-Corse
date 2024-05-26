
env_corse <- rast("data/env_corse_total_sync.tif")

env_corse$occ_density_cbnc
env_corse$occ_density_chiro
env_corse$distance_routes

bias <- env_corse[[c("occ_density_cbnc",
                     "occ_density_chiro",
                     "distance_routes")]]
bias$distance_routes <- 
  exp(-(bias$distance_routes / global(bias$distance_routes,
                                      "max", na.rm = T)[1, 1] + 1)^2)
# bias$distance_routes <- bias$distance_routes / 
#   global(bias$distance_routes,
#          "max", na.rm = T)[1, 1]

names(bias) <-
  c("a. Biais d'échantillonnage\ndes plantes",
    "b. Biais d'échantillonnage\ndes chiroptères",
    "c. Biais d'échantillonnage\nlié à l'accessibilité\naux routes")

png("outputs/biais.png", h = 500, w = 700)
ggplot() +
  geom_spatraster(data = bias) + 
  facet_wrap (~lyr) +
  scale_fill_viridis(option = "plasma")+
  xlab("Longitude") + 
  ylab("Latitude") +
  theme_minimal()
dev.off()
