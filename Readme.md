Code source du projet sur les modèles d’habitat pour les groupes
d’espèces PNA Corse
================
Boris Leroy
26 May, 2024

- [Cartographie prédictive des habitats des groupes d’espèces ciblées
  par les Plans Nationaux d’Actions en
  Corse](#cartographie-prédictive-des-habitats-des-groupes-despèces-ciblées-par-les-plans-nationaux-dactions-en-corse)
  - [Licence du projet](#licence-du-projet)
- [Utilisation du dépôt](#utilisation-du-dépôt)
  - [1. Préparation des données
    environnementales](#1-préparation-des-données-environnementales)
  - [2. Préparation des données
    espèces](#2-préparation-des-données-espèces)
  - [3. Modèles et résultats](#3-modèles-et-résultats)
- [Plus d’informations](#plus-dinformations)

# Cartographie prédictive des habitats des groupes d’espèces ciblées par les Plans Nationaux d’Actions en Corse

Ce dépôt contient le code source pour reproduire les analyses du projet.

## Licence du projet

[**L’ensemble du code est fourni sous licence libre
CeCILL-C**.](https://cecill.info/licences.fr.html)

La licence CeCILL-C est soumise au droit français et respectant les
principes de diffusion des logiciels libres. Vous pouvez utiliser,
modifier et/ou redistribuer ce programme sous les conditions de la
licence CeCILL-C telle que diffusée par le CEA, le CNRS et l’INRIA sur
le site “<http://www.cecill.info>”.

En contrepartie de l’accessibilité au code source et des droits de
copie, de modification et de redistribution accordés par cette licence,
il n’est offert aux utilisateurs qu’une garantie limitée. Pour les mêmes
raisons, seule une responsabilité restreinte pèse sur l’auteur du
programme, le titulaire des droits patrimoniaux et les concédants
successifs.

*La licence CeCILL-C implique une obligation de citation et de diffusion
du code sous licence libre en cas de réutilisation.*

**Citation recommandée :**

Leroy Boris. 2024. Cartographie prédictive des habitats des groupes
d’espèces ciblées par les Plans Nationaux d’Actions en Corse. Rapport
pour la DREAL de Corse. Zenodo. 110
pp. <https://doi.org/10.5281/zenodo.11067678>

# Utilisation du dépôt

Pour pouvoir lancer les fichiers rmarkdown le plus simple est de cloner
(télécharger) l’ensemble du dépôt.

Le dépôt contient cinq dossiers :

- data : contient les données brutes. Certaines données ne sont pas
  disponibles ici, il faut les télécharger en suivant les [liens de
  téléchargement des données brutes
  ici](http://borisleroy.com/sdms_pna_corse/cartes_variables.html)

- models : contient les modèles calibrés au format de stockage de
  biomod2

- outputs : contient les cartes finales au format raster

- scripts : contient les scripts préparatoires aux modèles

- preliminary_models : contient les modèles préliminaires, étape
  précédant les modèles finaux

Le dossier racine contient tous les fichiers Rmarkdown (`.Rmd`)
commentés pour lancer et analyser les modèles.

## 1. Préparation des données environnementales

La préparation et l’harmonisation des données environnementales est une
étape préalable au lancement des modèles. Elle a été réalisée dans les
scripts 01 et 02. Ces scripts sont basés sur les **données brutes** non
fournies dans le dépôt. Il est nécessaire de [télécharger les données
brutes en suivant les liens de cette page pour faire tourner ces
scripts](http://borisleroy.com/sdms_pna_corse/cartes_variables.html)

Le résultat de cette étape est un raster stack de variables
environnementales qui est fourni dans le dossier data sous le nom
`env_corse_total_sync.tif`

## 2. Préparation des données espèces

Les données espèces sont compressées dans le fichier `taxa.tar.gz`. Pour
les extraire il suffit de lancer le script `extraire_donnees_especes.R`.

## 3. Modèles et résultats

Les fichiers Rmarkdown à la racine du dépôt contiennent tous le code
utilisé pour calibrer et interpréter les modèles. Chaque fichier est
indépendant et peut être lancé seul, ou bien tous peuvent être lancés en
une seule fois avec le script 04.

# Plus d’informations

L’ensemble des infos sur ce projet peuvent être retrouvés sur cette page
: <http://borisleroy.com/sdms-pna-corse/>
