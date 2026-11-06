-- =====================================================================
-- Tiroir - 03_index.sql : un index par recherche fréquente
-- A exécuter après 01 et 02.
-- Les clés primaires et uniques (pseudo, email) sont déjà indexées par le schéma.
-- =====================================================================

USE tiroir;

-- ---------------------------------------------------------------------
-- R1 : les objets actifs d'une catégorie, du moins cher au plus cher
--   SELECT id_objet, titre, prix_jour
--   FROM objet
--   WHERE id_categorie = ? AND actif = 1
--   ORDER BY prix_jour ASC;
--
-- Index composite (id_categorie, actif, prix_jour) :
--  - id_categorie et actif sont des égalités : MySQL va directement au bon
--    bloc de l'index, sans parcourir toute la table ;
--  - prix_jour vient en dernier : à l'intérieur de ce bloc l'index est déjà
--    trié par prix, donc le tri ORDER BY est gratuit (pas de filesort).
--  Il remplace l'index implicite de la clé étrangère id_categorie
--  (id_categorie en est le préfixe, la clé étrangère reste servie).
-- ---------------------------------------------------------------------
CREATE INDEX idx_objet_categorie_actif_prix
    ON objet (id_categorie, actif, prix_jour);

-- ---------------------------------------------------------------------
-- R2 : savoir si un objet est libre entre deux dates (:debut, :fin)
--   SELECT COUNT(*) = 0 AS est_libre
--   FROM location
--   WHERE id_objet = ? AND statut = 'acceptee'
--     AND date_debut <= :fin AND date_fin >= :debut;
--
-- Index composite (id_objet, statut, date_debut, date_fin) :
--  - id_objet et statut (égalités) isolent les seules locations acceptées
--    de l'objet, qui sont peu nombreuses ;
--  - date_debut permet de borner la recherche par intervalle, et date_fin
--    est lue directement dans l'index (index couvrant : aucune lecture de
--    la table).
--  Le même index accélère le trigger anti-chevauchement du schéma (RG21),
--  qui exécute exactement cette recherche à chaque acceptation.
--  Il remplace l'index implicite de la clé étrangère id_objet.
-- ---------------------------------------------------------------------
CREATE INDEX idx_location_objet_statut_dates
    ON location (id_objet, statut, date_debut, date_fin);

-- ---------------------------------------------------------------------
-- R3 : l'historique des locations d'un membre, les plus récentes d'abord
--   SELECT *
--   FROM location
--   WHERE id_locataire = ?
--   ORDER BY date_debut DESC;
--
-- Index composite (id_locataire, date_debut) :
--  - id_locataire (égalité) ne garde que les locations du membre ;
--  - date_debut, trié dans l'index, est parcouru à l'envers pour fournir
--    directement le tri « plus récentes d'abord » sans filesort.
--  Il remplace l'index implicite de la clé étrangère id_locataire.
-- ---------------------------------------------------------------------
CREATE INDEX idx_location_locataire_debut
    ON location (id_locataire, date_debut);
