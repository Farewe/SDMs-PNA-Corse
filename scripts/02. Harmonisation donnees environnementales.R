library(terra)
library(sf)

env_corse <- rast("data/bioclim_corse.tif")

# 1. Distance aux routes
dist_routes <- rast("data/distance_route.tif")
dist_routes <- resample(dist_routes,
                        env_corse)
names(dist_routes) <- "distance_routes"
env_corse <- c(env_corse,
                   dist_routes)


# 2. Serpentinites
serpentinites <- rast("data/serpentinites_bin.tif")
serpentinites <- resample(serpentinites,
                          env_corse,
                          method = "sum")
serpentinites <- serpentinites / global(serpentinites, "max", na.rm = TRUE)[1, 1]

names(serpentinites) <- "serpentinites"
serpentinites[is.na(serpentinites)] <- 0
env_corse <- c(env_corse,
               serpentinites)

# 3. Milieux aquatiques
plan_eau <- rast("data/plan_eau_bin.tif")
cours_eau <- rast("data/cours_eau_bin.tif")

# Les milieux aquatiques sont particulièrement difficiles à traiter,
# car le mode de traitement peut avoir beaucoup d'influence sur le résultat.
# C'est surtout le changement de résolution qui est important à traiter,
# pour le passage de la résolution initiale très fine vers la résolution
# grossière des autres variables environnementales. Par exemple, pour 
# étudier la distance aux cours d'eau, rééchantillonner la variable binaire
# des cours d'eau à la résolution grossière puis mesurer la distance aux
# cours d'eau à la résolution grossire ne donnera pas le même résultat que 
# mesurer la distance aux cours d'eau à la résolution fine puis rééchantillonner
# vers la résolution grossière. 

# Les résolutions des deux variables sont très proches mais pas strictement
# identiques, donc on va les aligner 
res(plan_eau) < res(cours_eau)
# On aligne vers la plus grossière des deux résolutions
plan_eau <- resample(plan_eau,
                     cours_eau)

# On combine ensemble tous les milieux d'eau douce dans une seule variable
milieux_eaudouce <- sum(plan_eau,
                        cours_eau,
                        na.rm = TRUE)
# Et on ne garde que la valeur 1 pour indiquer présence d'un milieu d'eau douce
milieux_eaudouce[milieux_eaudouce > 1] <- 1

# On calcule la distance aux milieux d'eau douce à la résolution fine
dist_eau <- distance(milieux_eaudouce) # Opération très longue
# Puis on rééchantillonne la distance vers la résolution grossière
# en calculant la distance moyenne à un cours d'eau dans le pixel
dist_eau2 <- resample(dist_eau, 
                      env_corse,
                      method = "bilinear")
names(dist_eau2) <- "dist_moy_eau"
env_corse <- c(env_corse,
               dist_eau2)



# Ensuite, on calcule la proportion de milieux d'eau douce dans chaque pixel
# grossier en %
milieux_eaudouce <- resample(milieux_eaudouce,
                             env_corse,
                             method = "sum") # D'abord la somme
# On calcule la valeur maximale qui dépend du rapport entre les 
# résolutions, car les grilles ne sont pas pas parfaitement alignées
# (il y a ~16.18 pixels fins de la resolution fine dans un pixel grossier)
nb_max <- prod(res(env_corse)) / prod(res(plan_eau))

milieux_eaudouce <- milieux_eaudouce / 
  nb_max # Et on divise par le max
plot(milieux_eaudouce,
     col = viridis::viridis(12))
names(milieux_eaudouce) <- "milieux_eaudouce"

milieux_eaudouce[is.na(milieux_eaudouce)] <- 0

env_corse <- c(env_corse,
               milieux_eaudouce)


# 4. Potentialité de zones humides
zh_probables <- rast("data/zh_probables.tif")
# Même procédure que pour les milieux humides
dist_zh <- distance(zh_probables) 
dist_zh2 <- resample(dist_zh, 
                     env_corse,
                     method = "bilinear")
names(dist_zh2) <- "dist_moy_pzh"
env_corse <- c(env_corse,
               dist_zh2)


potentielles_zh <- resample(zh_probables,
                            env_corse,
                            method = "sum")
nb_max <- prod(res(env_corse)) / prod(res(zh_probables))

potentielles_zh <- potentielles_zh / 
  nb_max # Et on divise par le max
plot(potentielles_zh,
     col = viridis::viridis(12))
names(potentielles_zh) <- "potentielles_zh"
potentielles_zh[is.na(potentielles_zh)] <- 0

env_corse <- c(env_corse,
               potentielles_zh)

# writeRaster(env_corse, "data/env_corse.tif")
# 
# env_corse <- rast("data/env_corse.tif")

# 5. Occupation du sol
clc <- vect("data/clc_corse.gpkg")
clc <- project(clc, 
               env_corse)

# Bâti peu dense comme gîte pour les chiroptères
# Inclusion classe 112 (tissu urbain discontinu) 
# et classe 131 (extraction de matériaux) qui peuvent représenter des bâtiments 
# isolés et des mines
bati_peu_dense <- rasterizeGeom(clc[clc$code_18 %in% c("112", "131"), ],
                                env_corse, 
                                fun = "area")
bati_peu_dense <- bati_peu_dense / cellSize(bati_peu_dense)

names(bati_peu_dense) <- "bati_peu_dense"
env_corse <- c(env_corse,
               bati_peu_dense)

bati_peu_dense[bati_peu_dense == 0] <- NA
dist_bati_peu_dense <- distance(bati_peu_dense) 
names(dist_bati_peu_dense) <- "dist_bati_peu_dense"
env_corse <- c(env_corse,
               dist_bati_peu_dense)



# Zones ouvertes naturelles occupées par la végétation PNA des serpentinites
zones_ouvertes <- rasterizeGeom(clc[clc$code_18 %in% c("332", "333"), ],
                                env_corse, 
                                fun = "area")
zones_ouvertes <- zones_ouvertes / cellSize(zones_ouvertes)
names(zones_ouvertes) <- "zones_ouvertes"
env_corse <- c(env_corse,
               zones_ouvertes)

# Milieux forestiers pour les amphibiens, chiroptères
forets <- rasterizeGeom(clc[which(strtrim(clc$code_18, 2) == 31), ],
                        env_corse, 
                        fun = "area")
forets <- forets / cellSize(forets)
names(forets) <- "forets"
env_corse <- c(env_corse,
               forets)

# Distance aux forêts (chiroptères)
dist_forets <- forets
dist_forets[dist_forets == 0] <- NA
dist_forets <- distance(dist_forets)
names(dist_forets) <- "dist_forets"
env_corse <- c(env_corse,
               dist_forets)



# Forêts de feuillus / mixtes (pour les chiroptères)
forets_feuil_mix <- rasterizeGeom(clc[clc$code_18 %in% c("311", "313"), ],
                                  env_corse, 
                                  fun = "area")
forets_feuil_mix <- forets_feuil_mix / cellSize(forets_feuil_mix)
names(forets_feuil_mix) <- "forets_feuil_mix"
env_corse <- c(env_corse,
               forets_feuil_mix)

# writeRaster(env_corse,
#             "data/env_corse2.tif")


# Surfaces agricoles cultivées pouvant agir comme perturbations
milieux_agri <- rasterizeGeom(clc[clc$code_18 %in% c("211", "221", "222", 
                                                     "223" ), ],
                              env_corse, 
                              fun = "area")
milieux_agri <- milieux_agri / cellSize(milieux_agri)
names(milieux_agri) <- "milieux_agri"
env_corse <- c(env_corse,
               milieux_agri)


# Zones artificialisées
zones_artif <- rasterizeGeom(clc[clc$code_18 %in% c("111", "112", "121", "123",
                                                    "124", "131", "132"), ],
                           env_corse, 
                           fun = "area")
zones_artif <- zones_artif / cellSize(zones_artif)
names(zones_artif) <- "zones_artif"
env_corse <- c(env_corse,
               zones_artif)


# Milieux à végétation herbacée et/ou arbustive (papillons)
vege_herb <- rasterizeGeom(clc[which(strtrim(clc$code_18, 2) == 32), ],
                           env_corse, 
                           fun = "area")
vege_herb <- vege_herb / cellSize(vege_herb)
names(vege_herb) <- "vege_herb"
env_corse <- c(env_corse,
               vege_herb)



# Diversité d'habitats naturels
clc_codes <- unique(clc$code_18)
# On retire les milieux marins et les milieux urbains
clc_codes <- clc_codes[-which(clc_codes > 500 | clc_codes < 200)]

clc_all_classes <- rast()
for (cur_clc in clc_codes) {
  clc_all_classes <- c(clc_all_classes,
                       rasterizeGeom(clc[clc$code_18 %in% cur_clc, ],
                                     env_corse, 
                                     fun = "area"))
}

names(clc_all_classes) <- clc_codes
clc_all_classes <- clc_all_classes / sum(clc_all_classes, na.rm = TRUE)

simpson_div <- app(clc_all_classes,
                   function(x, na.rm) 1 - sum(x^2))

simpson_div[simpson_div == 1] <- NA

plot(simpson_div, col = viridis::viridis(12))
names(simpson_div) <- "simpson_landscapediv"
env_corse <- c(env_corse,
               simpson_div)




# Pollution lumineuse
pollum <- rast("data/pollutionlumineuse.tif")
pollum <- resample(pollum,
                   env_corse)
names(pollum) <- "pollum"
env_corse <- c(env_corse,
               pollum)


# Naturalité et variables associées
connectivite <- rast("data/continuite.tif")
names(connectivite) <- "connectivite"
connectivite <- resample(connectivite,
                         env_corse)
integrite <- rast("data/integrite_biophysique.tif")
names(integrite) <- "integrite"
integrite <- resample(integrite,
                      env_corse)
naturalite <- rast("data/naturalite.tif")
names(naturalite) <- "naturalite"
naturalite <- resample(naturalite,
                       env_corse)

plot(c(connectivite, integrite, naturalite), col = viridis::viridis(12))

env_corse <- c(env_corse,
               connectivite,
               integrite,
               naturalite)


# Densité de population
pop_dens <- rast("data/pop_dens_log10.tif")
names(pop_dens) <- "pop_dens_log10"
env_corse <- c(env_corse,
               pop_dens)

# Biais d'échantillonnage plantes
rast_dens_cbnc <- rast("data/occ_density_cbnc.tif")
names(rast_dens_cbnc) <- "occ_density_cbnc"
env_corse <- c(env_corse,
               rast_dens_cbnc)


# Cavités
cavites <- rast("data/cavites.tif")
dist_cavites <- distance(cavites)
names(dist_cavites) <- "dist_cavites"

env_corse <- c(env_corse,
               dist_cavites)

writeRaster(env_corse, 
            "data/env_corse_total.tif",
            overwrite = TRUE)

env_corse <- rast("data/env_corse_total.tif")

# Pins laricio (Sittelle Corse)
laricio <- vect("data/forets_laricio.gpkg")
laricio_r <- rasterizeGeom(laricio,
                           env_corse, 
                           fun = "area")
laricio_r <- laricio_r / cellSize(laricio_r)

names(laricio_r) <- "laricio"
env_corse <- c(env_corse,
               laricio_r)

# Températures fraiches de la saison estivale (chiroptères)
tasmin_chiro <- rast("data/tasmin_chiro.tif")
names(tasmin_chiro) <- "tasmin_chiro"
env_corse <- c(env_corse,
               tasmin_chiro)


# Biais d'échantillonnage chiroptères
occ_density_chiro <- rast("data/occ_density_chiro.tif")
names(occ_density_chiro) <- "occ_density_chiro"
env_corse <- c(env_corse,
               occ_density_chiro)


library(virtualspecies)
env_corse <- synchroniseNA(env_corse)

writeRaster(env_corse, 
            "data/env_corse_total_sync.tif",
            overwrite = TRUE)


