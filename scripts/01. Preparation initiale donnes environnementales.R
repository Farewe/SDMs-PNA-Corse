# Téléchargement initial et création des données environnementales
# Script à ne lancer qu'une fois

library(terra)
library(sf)
library(rnaturalearth)


# 1. Limites de la France pour la carte
# Autoriser l'installation de rnaturalearthhires
fra <- ne_countries(scale = 10,
                    country = "france",
                    returnclass = "sf")
st_write(fra,
         "data/fra.gpkg",
         append = FALSE)



# 2. Données climatiques (CHELSA)
# 2.1 Création des noms de toutes les variables à télécharger sur CHELSA climate
# Toutes les variables sont décrites dans le pdf ci-dessous
# https://chelsa-climate.org/wp-admin/download-page/CHELSA_tech_specification_V2.pdf
vars <- c(paste0("bio", 1:19), # Variables bioclimatiques
          paste0("cmi_", c("max", "mean", "min", "range")), # Indices d'humidité
          paste0("gdd", c("0", "5", "10")), # Cumul des températures sur les jours de croissance
          "gsl", # Durée de la saison de croissance
          "gsp", # Précipitations durant la saison de croissance
          "gst", # Température moyenne durant la saison de croissance
          paste0("hurs_", c("max", "mean", "min", "range")), # Humidité de surface relative
          paste0("ngd", c("0", "5", "10")), # Nombre de jours de croissance
          "npp", # Productivité primaire nette
          paste0("pet_penman_", c("max", "mean", "min", "range")), # Evapotranspiration
          paste0("rsds_", c("max", "mean", "min", "range")), # Radiation solaire
          "scd", # Nombre de jours de couverture neigeuse
          paste0("sfcWind_",  c("max", "mean", "min", "range")), # Vent à 10m au dessus du sol
          # paste0("tcc_",  c("max", "mean", "min", "range")), # Couverture nuageuse
          # La couverture nuageuse est manquante sur CHELSA actuellement
          paste0("vpd_", c("max", "mean", "min", "range")) # Déficit de pression de vapeur
          )
vars <- data.frame(vars = vars)
# xlsx::write.xlsx(vars, "data/chelsa_variable_names2.xlsx",
# row.names = FALSE)
saveRDS(vars, "data/chelsa_variable_names.RDS")
vars <- xlsx::read.xlsx("data/chelsa_variable_names.xlsx",
                        sheetIndex = 1)
vars$explanation <- gsub("\n", " ", vars$explanation)

# 2.2 Telechargement des données CHELSA
# Les données de radiation solaire sont nommées de manière non conventionnelle
# sur CHELSA, donc il faut faire un cas particulier avec le if()
for(bioclim in vars) {
  if(length(grep("rsds", bioclim))) {
    bioclimsplit <- unlist(strsplit(bioclim, "_"))
    addresse <- paste0(
      "https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/bio/CHELSA_",
      bioclimsplit[1], "_1981-2010_", bioclimsplit[2], "_V.2.1.tif")
  } else {
    addresse <- paste0(
      "https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/climatologies/1981-2010/bio/CHELSA_",
      bioclim, "_1981-2010_V.2.1.tif")
  }
  download.file(addresse,
    destfile = paste0("./data/donnees_brutes/bioclim/CHELSA_", bioclim, ".tif"),
    method = "wget", quiet = TRUE)
}

# Création de variables de température min pour les chiroptères
for(month in 5:9) {
  download.file(paste0(
    "https://os.zhdk.cloud.switch.ch/envicloud/chelsa/chelsa_V2/GLOBAL/",
    "climatologies/1981-2010/tasmin/CHELSA_tasmin_0",
    month,
    "_1981-2010_V.2.1.tif"),
    destfile = paste0("./data/donnees_brutes/tas/tasmin_0", month, ".tif"),
    method = "libcurl", quiet = TRUE,
    mode = "wb")
}

# 2.3 Réduction à l'étendue de la Corse
extent_corse <- ext(8.442096, 9.65557, 41.32005, 43.07262)

for(bioclim in vars) {
  cur_var <- rast(paste0("data/donnees_brutes/bioclim/CHELSA_",
                         bioclim, ".tif"))
  cur_var <- crop(cur_var,
                  extent_corse)
  writeRaster(cur_var,
              paste0("data/bioclim/CHELSA_",
                     bioclim, ".tif"))
}

tasmin_chiro <- rast(paste0("data/donnees_brutes/tas/tasmin_0", 5:9,
                            ".tif"))
tasmin_chiro <- crop(tasmin_chiro,
                     extent_corse)
tasmin_chiro <- app(tasmin_chiro,
                    "min")
names(tasmin_chiro) <- "tasmin_chiro"
writeRaster(tasmin_chiro, "data/tasmin_chiro.tif",
            overwrite = TRUE)

# 2.4 Harmonisation des données manquantes entre couches
bioclim_corse <- rast(paste0("data/bioclim/CHELSA_", 
                             vars, ".tif"))
names(bioclim_corse) <- vars

library(virtualspecies)

bioclim_corse <- synchroniseNA(bioclim_corse)

writeRaster(bioclim_corse,
            "data/bioclim_corse.tif",
            overwrite = TRUE)


# 3. Distance aux routes
roads <- rast("data/donnees_brutes/RASTER/ROUTES_WGS84.tif")
distance_roads <- distance(roads)

writeRaster(distance_roads, 
            "data/distance_route.tif")

# 4. Carte géologique
## 4.1 Grandes classes géologiques
geol <- st_read("data/donnees_brutes/VECTEUR/GEOL_Corse_BRGM_500K.shp")
geol <- st_transform(geol, 
                     crs = "EPSG:4326")
st_write(geol, 
         "data/geol_corse.gpkg")

## 4.2 Serpentinites
serpentinites <- rast("data/donnees_brutes/RASTER/SERPENTINITES_WGS84.tif")
serpentinites[serpentinites == 10] <- 1
writeRaster(serpentinites,
            "data/serpentinites_bin.tif",
            overwrite = TRUE)

# 5. Habitats aquatiques
cours_eau <- rast("data/donnees_brutes/RASTER/BD_TOPAGE_Cours_Eau_WGS84.tif")
plan_eau <- rast("data/donnees_brutes/RASTER/BD_TOPAGE_PLAN_EAU_WGS84.tif")
TRH <- rast("data/donnees_brutes/raster/BD_TOPAGE_Troncon_Hydrographique_WGS84.tif")

## 5.1 Variables binaires
cours_eau[cours_eau == 10] <- 1
plan_eau[plan_eau == 10] <- 1
TRH[TRH == 10] <- 1

writeRaster(cours_eau, 
            "data/cours_eau_bin.tif")
writeRaster(plan_eau, 
            "data/plan_eau_bin.tif")
writeRaster(TRH, 
            "data/troncon_hydro_bin.tif")

## 5.2 Distance aux cours d'eau et plans d'eau
plan_eau_coarse <- resample(plan_eau,
                            bioclim_corse)
dist_plan_eau <- distance(plan_eau_coarse)

writeRaster(dist_plan_eau,
            "data/dist_plan_eau.tif")

cours_eau_coarse <- resample(cours_eau,
                             bioclim_corse)
dist_cours_eau <- distance(cours_eau_coarse)

writeRaster(dist_cours_eau,
            "data/dist_plan_eau.tif")

## 5.3 Potentialité de zone humide
ehr <- rast("data/donnees_brutes/RASTER/EHR_WGS84.tif")
ehr[ehr == 10] <- 1
writeRaster(ehr,
            "data/zh_probables.tif",
            overwrite = TRUE)

# 6. Variables d'occupation des sols
## 6.1 Corine Land Cover (= reference)
clc <- st_read("data/donnees_brutes/VECTEUR/CLC_2018.gpkg") # Utiliser la nomenclature au niveau 2

classes_corse <- unique(as.data.frame(st_drop_geometry(clc[, c("code_18", "clc_nomenc")])))
classes_corse <- classes_corse[order(classes_corse$code_18), ]

# Categories pour la Corse :
# Zones artificielles = CLC 1
# Zones agricoles = CLC 2
clc$cats_corse <- strtrim(clc$code_18, 1)
# Forets = CLC 3.1
clc$cats_corse[strtrim(clc$code_18, 2) == 31] <- 31
# Prairies et landes = CLC 3.2
clc$cats_corse[strtrim(clc$code_18, 2) == 32] <- 32
# Milieux ouverts avec peu de végétation = CLC 3.3
clc$cats_corse[strtrim(clc$code_18, 2) == 33] <- 33
# Milieux ouverts type rocailleux / éboulis pour végétation
# des serpentinites
clc$cats_corse[clc$code_18 %in% c(332, 333)] <- 332
# Zones humides = CLC 4.1
clc$cats_corse[strtrim(clc$code_18, 2) == 41] <- 41
# Zones humides saumâtres = CLC 4.2
clc$cats_corse[strtrim(clc$code_18, 2) == 42] <- 42
# Plans d'eau = CLC 5.1.2 (incluant les lagunes littorales 5.2.1 ici)
clc$cats_corse[clc$code_18 %in% c(512, 521)] <- 512

st_write(clc, "data/clc_corse.gpkg", append = FALSE)

## 6.2 BD_FORET = pour des variables spécifiques seulement
### 6.2.1 Pins laricios
forets_vect <- st_read("data/donnees_brutes/VECTEUR/Vecteur_SDM.gpkg",
                       layer = "BD_FORET")
# Correction du problème d'encodage
forets_vect$TFV <- iconv(forets_vect$TFV, from = "UTF-8", to = "ISO-8859-1")
forets_vect$TFV_G11 <- iconv(forets_vect$TFV_G11, 
                             from = "UTF-8", to = "ISO-8859-1")
forets_laricio <- forets_vect[forets_vect$TFV == 
                                "Forêt fermée de pin laricio ou pin noir pur", ]
forets_laricio <- st_transform(forets_laricio, crs = "EPSG:4326")
st_write(forets_laricio,
         "data/forets_laricio.gpkg")

## 6.3 Tâche urbaine binaire
padduc <- rast("data/donnees_brutes/RASTER/PADDUC_TU_WGS84.tif")
padduc[padduc == 10] <- 1
writeRaster(padduc,
            "data/padduc_bin.tif")


# 7. Exposition solaire : remplacée par les données de rayonnement, donc pas nécessaire ici
# expo <- rast("data/RASTER/Exposition_1km_WGS84.tif")
# 
# # Transformation de l'angle en radians 
# radians <- (expo / 360) * 2 * pi
# 
# # Axe Est-Ouest
# sin_solar_orientation = sin(radians)
# # Axe Nord-Sud
# cos_solar_orientation = cos(radians)

# 8. Altitude
mnt <- rast("data/donnees_brutes/RASTER/MNT_1km_MOY_WGS84.tif")
writeRaster(mnt, 
            "data/altitude.tif")

# 9. Pente
pente <- rast("data/donnees_brutes/RASTER/Pente_1km_WGS84.tif")
writeRaster(pente, 
            "data/pente.tif")

# 10. Densité de population humaine
pop_dens <- rast("data/donnees_brutes/RASTER/baseYr_total_2000.tif")
pop_dens <- crop(pop_dens,
                 extent_corse)

writeRaster(pop_dens, 
            "data/pop_dens.tif",
            overwrite = TRUE)
writeRaster(log10(pop_dens + 1), 
            "data/pop_dens_log10.tif",
            overwrite = TRUE)

# 11. Naturalité
ext_corse <- ext(1145000, 1261000, 6000000, 6250000)
# Intégrité biophysique
integrite <- rast("data/donnees_brutes/RASTER/naturalite/Layer1_FINAL.tif")
integrite <- crop(integrite, ext_corse)
integrite <- project(integrite, "EPSG:4326")

writeRaster(integrite, 
            "data/integrite_biophysique.tif")

# Continuité spatiale
continuite <- rast("data/donnees_brutes/RASTER/naturalite/Layer3_FINAL.tif")
continuite <- crop(continuite, ext_corse)
continuite <- project(continuite, "EPSG:4326")

writeRaster(continuite, 
            "data/continuite.tif")


# Naturalité
naturalite <- rast("data/donnees_brutes/RASTER/naturalite/Layer4_FINAL.tif")
naturalite <- crop(naturalite, ext_corse)
naturalite <- project(naturalite, "EPSG:4326")

writeRaster(naturalite, 
            "data/naturalite.tif")


# 12. Pollution lumineuse
library(XML)
library(RCurl)

# Téléchargement des rasters de pollution lumineuse de août et septembre 
# = seules données disponibles pour la Corse en période d'activité des chauves
# souris
year <- 2013:2019
month <- formatC(8:9, width=2, flag = 0)

unique_id <- NULL
for(y in year) {
  for (m in month) {
    dmax <- ifelse(m %in% "08",
                   31, 
                   30)
    adresse <- paste0("https://eogdata.mines.edu/nighttime_light/monthly/v10/",
                      y, "/", y, m,
                      "/vcmcfg/")
    
    result <- getURL(adresse,
                     verbose=TRUE, ftp.use.epsv=FALSE, dirlistonly = TRUE,
                     crlf = TRUE)
    result <- unlist(strsplit(result, 
                              paste0("SVDNB_npp_",
                              y, m, "01-", y, m, dmax, 
                              "_75N060W_vcmcfg_v10_")))[2]
    result <- unlist(strsplit(result, "\\.tgz"))[1]
    
    adresse <- paste0(adresse,
                      "SVDNB_npp_",
                             y, m, "01-", y, m, dmax, 
                             "_75N060W_vcmcfg_v10_",
                      result, ".tgz")
    
    download.file(adresse,
                  destfile = paste0("./data/donnees_brutes/RASTER/pollum/",
                                    y, m, ".tgz"),
                  method = "auto", quiet = TRUE)
    
    untar(paste0("./data/donnees_brutes/RASTER/pollum/",
                 y, m, ".tgz"),
          exdir = "data/donnees_brutes/RASTER/pollum")
    
    unique_id <- rbind.data.frame(
      unique_id,
      data.frame(year = y,
                 month = m,
                 dmax = dmax,
                 uid = result)
    )
  }
}

extent_corse <- ext(8.442096, 9.65557, 41.32005, 43.07262)

pollum <- rast()
for (i in 1:nrow(unique_id)) {
  
  light <- rast(paste0("data/donnees_brutes/RASTER/pollum/SVDNB_npp_",
                       unique_id$year[i],
                       unique_id$month[i],
                       "01-",
                       unique_id$year[i],
                       unique_id$month[i],
                       unique_id$dmax[i],
                       "_75N060W_vcmcfg_v10_",
                       unique_id$uid[i],
                       ".avg_rade9h.tif"))
  light <- crop(light, extent_corse)
  
  pollum <- c(pollum, 
              light)
}

bioclim_corse <- rast("data/bioclim_corse.tif")
pollum <- resample(pollum,
                   bioclim_corse)
pollum <- app(pollum,
              "mean")
writeRaster(pollum,
            "pollutionlumineuse.tif")


# 13. Biais d'échantillonnage plantes
occ_cbnc <- readxl::read_excel("data/donnees_brutes/donneesCBNC.xlsx",
                        sheet = 1)
occ_cbnc <- as.data.frame(occ_cbnc)

# Retrait des duplicatas espèce - relevé
occ_cbnc <- occ_cbnc[-which(
  duplicated(as.data.frame(occ_cbnc[, c("nom_cite", "id_releve")]))), ]

occ_cbnc$x_l93 <- as.numeric(occ_cbnc$x_l93)
occ_cbnc$y_l93 <- as.numeric(occ_cbnc$y_l93)

if(length(is.na(which(is.na(occ_cbnc$x_l93))))) {
  occ_cbnc <- occ_cbnc[-which(is.na(occ_cbnc$x_l93)), ]
}

occ_cbnc <- vect(occ_cbnc,
                 geom = c("x_l93", "y_l93"))
crs(occ_cbnc) <- "EPSG:2154"


occ_cbnc <- project(occ_cbnc,
                    "EPSG:4326")

bioclim_corse <- rast("data/bioclim_corse.tif")

density_cbnc <- MASS::kde2d(crds(occ_cbnc)[, 1],
                            crds(occ_cbnc)[, 2],
                            n = dim(bioclim_corse)[2:1],
                            lims = as.vector(ext(bioclim_corse)))

rast_dens_cbnc = expand.grid(x = density_cbnc$x, y = density_cbnc$y, KEEP.OUT.ATTRS = FALSE)
rast_dens_cbnc$z = as.vector(density_cbnc$z)
rast_dens_cbnc = rast(rast_dens_cbnc)

rast_dens_cbnc <- resample(rast_dens_cbnc,
                           bioclim_corse)
rast_dens_cbnc <- rast_dens_cbnc / global(rast_dens_cbnc,
                                          "max")[1, 1]
writeRaster(rast_dens_cbnc,
            "data/occ_density_cbnc.tif", overwrite = TRUE)


# 14. Cavités 
cavites_2A <- read.csv("data/donnees_brutes/vecteur/cavite_2A.csv",
                       sep = ";")
cavites_2B <- read.csv("data/donnees_brutes/vecteur/cavite_2B.csv",
                       sep = ";")
cavites <- rbind(cavites_2A,
                 cavites_2B)
cavites <- cavites[-which(cavites$positionnement %in% c("centroide de commune", 
                                                        "imprécis")), ]

# Les coordonnées de certaines cavités sont confidentielles et donc manquantes
cavites <- cavites[-which(is.na(cavites$xouvl2e)), ]
cavites <- vect(cavites,
                 geom = c("xouvl2e", "youvl2e"))
crs(cavites) <- "EPSG:27572"

cavites <- project(cavites,
                   "EPSG:4326")

cavites_rast <- rasterize(cavites,
                          bioclim_corse)
writeRaster(cavites_rast, 
            "data/cavites.tif")



### Emprise spatiale de la Corse
corse2a <- st_read("data/donnees_brutes/VECTEUR/admin-departement2a.shp")
corse2b <- st_read("data/donnees_brutes/VECTEUR/admin-departement2b.shp")

corse <- st_union(corse2a, corse2b)
st_write(corse, "data/corse.gpkg",
         append = FALSE)


# 15. Biais d'échantillonnage chiroptères
chiroforet <- st_read("data/donnees_brutes/taxa/Chiro_forestier.shp")
# Simplification du nom d'espèce en binomial
chiroforet$species <- simplify_species_name(chiroforet$nom_valide)
# Retrait d'une araignée qui s'est glissée par erreur dans le groupe des
# chiroptères
chiroforet <- chiroforet[-which(chiroforet$species %in% 
                                  "Enoplognatha thoracica"), ]

chirozh <- st_read("data/donnees_brutes/taxa/Chiro_ZH.shp")
# Simplification du nom d'espèce en binomial
chirozh$species <- simplify_species_name(chirozh$nom_valide)

chirocavern <- st_read("data/donnees_brutes/taxa/Chiro_cavernicoles.shp")
# Simplification du nom d'espèce en binomial
chirocavern$species <- simplify_species_name(chirocavern$nom_valide)

occ_chiro_total <- rbind(chiroforet,
                         chirozh,
                         chirocavern)

occ_chiro_total <- occ_chiro_total[-which(
  duplicated(as.data.frame(occ_chiro_total[, c("species", "x_centroid", "y_centroid")]))), ]


occ_chiro_total <- as_spatvector(occ_chiro_total)

bioclim_corse <- rast("data/bioclim_corse.tif")

density_chiro <- MASS::kde2d(crds(occ_chiro_total)[, 1],
                             crds(occ_chiro_total)[, 2],
                             n = dim(bioclim_corse)[2:1],
                             lims = as.vector(ext(bioclim_corse)))

rast_dens_chiro = expand.grid(x = density_chiro$x, y = density_chiro$y, KEEP.OUT.ATTRS = FALSE)
rast_dens_chiro$z = as.vector(density_chiro$z)
rast_dens_chiro = rast(rast_dens_chiro)

rast_dens_chiro <- resample(rast_dens_chiro,
                           bioclim_corse)
rast_dens_chiro <- rast_dens_chiro / global(rast_dens_chiro,
                                          "max")[1, 1]

plot(rast_dens_chiro)
writeRaster(rast_dens_chiro,
            "data/occ_density_chiro.tif", overwrite = TRUE)
