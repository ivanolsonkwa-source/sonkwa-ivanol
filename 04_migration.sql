-- =====================================================================
-- Tiroir - 04_migration.sql : ajout de la commission sur les locations
-- A exécuter après 01, 02 et 03. La base est en production et remplie.
--
-- Stratégie : 3 étapes, aucune ne bloque la table longtemps.
--   1. Ajout de la colonne sans verrou (DDL en ligne).
--   2. Remplissage des locations terminées par petits lots.
--   3. Contrôle.
-- L'étape 2 est reprenable après interruption (elle ne retouche pas une
-- commission déjà renseignée) ; l'étape 1 ne se joue qu'une fois.
-- =====================================================================

USE tiroir;

-- ---------------------------------------------------------------------
-- 1. Ajout de la colonne, sans bloquer la table
--    - DECIMAL(10,2) : euros avec 2 décimales (même précision que prix_total)
--    - NOT NULL DEFAULT 0.00 : jamais vide, 0 par défaut ; les lignes
--      existantes reçoivent 0.00 sans qu'on ait à les réécrire
--    - ALGORITHM=INPLACE, LOCK=NONE : lectures ET écritures restent
--      possibles pendant la modification (échoue plutôt que de verrouiller
--      si le moteur ne sait pas faire autrement).
-- ---------------------------------------------------------------------
ALTER TABLE location
    ADD COLUMN commission DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER prix_total,
    ALGORITHM = INPLACE, LOCK = NONE;

-- ---------------------------------------------------------------------
-- 2. Remplissage : 10 % du prix total pour les locations déjà terminées.
--    Un seul gros UPDATE verrouillerait toutes les lignes touchées pendant
--    toute sa durée : on traite par lots de 1000 lignes, chaque lot dans
--    sa propre transaction (autocommit), ce qui laisse passer les écritures
--    concurrentes entre deux lots.
--    La condition commission = 0.00 rend la reprise possible après
--    interruption et évite de recalculer ce qui est fait.
-- ---------------------------------------------------------------------
DELIMITER $$

DROP PROCEDURE IF EXISTS tmp_remplir_commission$$
CREATE PROCEDURE tmp_remplir_commission()
BEGIN
    DECLARE v_lignes INT DEFAULT 1;
    WHILE v_lignes > 0 DO
        UPDATE location
           SET commission = ROUND(prix_total * 0.10, 2)
         WHERE statut = 'terminee'
           AND commission = 0.00
           AND prix_total > 0
         LIMIT 1000;
        SET v_lignes = ROW_COUNT();
    END WHILE;
END$$

DELIMITER ;

CALL tmp_remplir_commission();
DROP PROCEDURE tmp_remplir_commission;

-- ---------------------------------------------------------------------
-- 3. Contrôle : doit retourner 0 ligne (toute location terminée a bien
--    une commission égale à 10 % de son prix total).
-- ---------------------------------------------------------------------
SELECT id_location, prix_total, commission
FROM location
WHERE statut = 'terminee'
  AND commission <> ROUND(prix_total * 0.10, 2);
