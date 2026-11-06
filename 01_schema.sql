-- =====================================================================
-- Tiroir - 01_schema.sql : MPD MySQL (8.0.16+ requis pour les CHECK)
-- A exécuter sur une base vide, avant 02, 03 et 04.
-- Les règles RGxx font référence à regles.txt.
-- =====================================================================

DROP DATABASE IF EXISTS tiroir;
CREATE DATABASE tiroir CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tiroir;

-- ---------------------------------------------------------------------
-- MEMBRE (RG01, RG02, RG03, RG04)
-- ---------------------------------------------------------------------
CREATE TABLE membre (
    id_membre   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    nom         VARCHAR(80)   NOT NULL,
    prenom      VARCHAR(80)   NOT NULL,
    pseudo      VARCHAR(50)   NOT NULL,
    email       VARCHAR(190)  NOT NULL,
    telephone   VARCHAR(20)   NOT NULL,
    code_postal CHAR(5)       NOT NULL,
    CONSTRAINT pk_membre        PRIMARY KEY (id_membre),
    CONSTRAINT uq_membre_pseudo UNIQUE (pseudo),                 -- RG02
    CONSTRAINT uq_membre_email  UNIQUE (email),                  -- RG03
    CONSTRAINT ck_membre_cp     CHECK (code_postal REGEXP '^[0-9]{5}$')
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- CATEGORIE (RG10, RG11, RG12) : association réflexive via id_categorie_parent
-- ---------------------------------------------------------------------
CREATE TABLE categorie (
    id_categorie        INT UNSIGNED NOT NULL AUTO_INCREMENT,
    nom                 VARCHAR(80)  NOT NULL,
    id_categorie_parent INT UNSIGNED NULL,                        -- NULL = catégorie racine
    CONSTRAINT pk_categorie PRIMARY KEY (id_categorie),
    CONSTRAINT fk_categorie_parent FOREIGN KEY (id_categorie_parent)
        REFERENCES categorie (id_categorie) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_categorie_nom_parent UNIQUE (nom, id_categorie_parent)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- OBJET (RG05 à RG09)
-- ---------------------------------------------------------------------
CREATE TABLE objet (
    id_objet     INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    titre        VARCHAR(150)  NOT NULL,
    description  TEXT          NOT NULL,
    prix_jour    DECIMAL(8,2)  NOT NULL,
    caution      DECIMAL(8,2)  NOT NULL DEFAULT 0.00,
    etat         ENUM('neuf','très bon','bon','usé') NOT NULL,    -- RG07
    actif        TINYINT(1)    NOT NULL DEFAULT 1,                -- RG09 : 0 = en pause
    id_membre    INT UNSIGNED  NOT NULL,                          -- RG05 : propriétaire
    id_categorie INT UNSIGNED  NOT NULL,                          -- RG10 : une seule catégorie
    CONSTRAINT pk_objet PRIMARY KEY (id_objet),
    CONSTRAINT fk_objet_membre FOREIGN KEY (id_membre)
        REFERENCES membre (id_membre) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_objet_categorie FOREIGN KEY (id_categorie)
        REFERENCES categorie (id_categorie) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_objet_prix    CHECK (prix_jour > 0),            -- RG08
    CONSTRAINT ck_objet_caution CHECK (caution >= 0),
    CONSTRAINT ck_objet_actif   CHECK (actif IN (0,1))
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PHOTO (RG13, RG14, RG15) : entité faible, identifiée par (objet, numéro)
-- ---------------------------------------------------------------------
CREATE TABLE photo (
    id_objet INT UNSIGNED  NOT NULL,
    numero   SMALLINT UNSIGNED NOT NULL,
    url      VARCHAR(255)  NOT NULL,
    CONSTRAINT pk_photo PRIMARY KEY (id_objet, numero),           -- RG14
    CONSTRAINT fk_photo_objet FOREIGN KEY (id_objet)
        REFERENCES objet (id_objet) ON DELETE CASCADE ON UPDATE CASCADE,   -- RG15
    CONSTRAINT ck_photo_numero CHECK (numero >= 1)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- LOCATION (RG16 à RG22)
-- ---------------------------------------------------------------------
CREATE TABLE location (
    id_location   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    date_debut    DATE          NOT NULL,
    date_fin      DATE          NOT NULL,
    prix_total    DECIMAL(10,2) NOT NULL,                         -- RG18 : figé à la demande
    statut        ENUM('demandee','acceptee','refusee','annulee','terminee')
                  NOT NULL DEFAULT 'demandee',                    -- RG19
    id_objet      INT UNSIGNED  NOT NULL,
    id_locataire  INT UNSIGNED  NOT NULL,
    CONSTRAINT pk_location PRIMARY KEY (id_location),
    CONSTRAINT fk_location_objet FOREIGN KEY (id_objet)
        REFERENCES objet (id_objet) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_location_locataire FOREIGN KEY (id_locataire)
        REFERENCES membre (id_membre) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_location_dates CHECK (date_fin >= date_debut),  -- RG17
    CONSTRAINT ck_location_prix  CHECK (prix_total >= 0)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- AVIS (RG23 à RG26) : identifié par (location, sens)
--   sens = rôle de l'auteur : 'LOCATAIRE' note l'objet, 'PROPRIETAIRE' note le locataire.
--   La clé primaire garantit au maximum un avis de chaque côté (RG26).
-- ---------------------------------------------------------------------
CREATE TABLE avis (
    id_location INT UNSIGNED NOT NULL,
    sens        ENUM('LOCATAIRE','PROPRIETAIRE') NOT NULL,
    note        TINYINT UNSIGNED NOT NULL,
    commentaire TEXT NULL,                                        -- RG25 : facultatif
    date_avis   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_avis PRIMARY KEY (id_location, sens),           -- RG26
    CONSTRAINT fk_avis_location FOREIGN KEY (id_location)
        REFERENCES location (id_location) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT ck_avis_note CHECK (note BETWEEN 1 AND 5)          -- RG24
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- FAVORI (RG27, RG28)
-- ---------------------------------------------------------------------
CREATE TABLE favori (
    id_membre  INT UNSIGNED NOT NULL,
    id_objet   INT UNSIGNED NOT NULL,
    date_ajout DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,   -- RG28
    CONSTRAINT pk_favori PRIMARY KEY (id_membre, id_objet),       -- RG27
    CONSTRAINT fk_favori_membre FOREIGN KEY (id_membre)
        REFERENCES membre (id_membre) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_favori_objet FOREIGN KEY (id_objet)
        REFERENCES objet (id_objet) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================================
-- TRIGGERS : règles qu'un simple CHECK ne peut pas garantir
-- (un CHECK ne peut pas consulter une autre ligne ni une autre table).
-- =====================================================================
DELIMITER $$

-- RG12 : une catégorie ne peut pas être sa propre sous-catégorie, ni directe
-- ni indirecte (A dans B dans A). On remonte la chaîne des parents.
CREATE TRIGGER trg_categorie_bu_pas_de_cycle
BEFORE UPDATE ON categorie
FOR EACH ROW
BEGIN
    DECLARE v_cur INT UNSIGNED;
    DECLARE v_prof INT DEFAULT 0;
    SET v_cur = NEW.id_categorie_parent;
    WHILE v_cur IS NOT NULL AND v_prof < 100 DO
        IF v_cur = NEW.id_categorie THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'RG12 : une catégorie ne peut pas être sa propre sous-catégorie';
        END IF;
        SELECT id_categorie_parent INTO v_cur FROM categorie WHERE id_categorie = v_cur;
        SET v_prof = v_prof + 1;
    END WHILE;
END$$

-- RG20 : on ne peut pas louer son propre objet (insertion)
-- RG21 : pas de chevauchement de deux locations acceptées sur un même objet
CREATE TRIGGER trg_location_bi_regles
BEFORE INSERT ON location
FOR EACH ROW
BEGIN
    IF NEW.id_locataire = (SELECT id_membre FROM objet WHERE id_objet = NEW.id_objet) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG20 : un membre ne peut pas louer son propre objet';
    END IF;
    IF NEW.statut = 'acceptee' AND EXISTS (
            SELECT 1 FROM location l
            WHERE l.id_objet = NEW.id_objet
              AND l.statut = 'acceptee'
              AND l.date_debut <= NEW.date_fin
              AND l.date_fin   >= NEW.date_debut) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG21 : cet objet a déjà une location acceptée sur cette période';
    END IF;
END$$

CREATE TRIGGER trg_location_bu_regles
BEFORE UPDATE ON location
FOR EACH ROW
BEGIN
    IF NEW.id_locataire = (SELECT id_membre FROM objet WHERE id_objet = NEW.id_objet) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG20 : un membre ne peut pas louer son propre objet';
    END IF;
    IF NEW.statut = 'acceptee' AND EXISTS (
            SELECT 1 FROM location l
            WHERE l.id_objet = NEW.id_objet
              AND l.statut = 'acceptee'
              AND l.id_location <> NEW.id_location
              AND l.date_debut <= NEW.date_fin
              AND l.date_fin   >= NEW.date_debut) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG21 : cet objet a déjà une location acceptée sur cette période';
    END IF;
    -- RG23 : une location qui porte déjà des avis doit rester terminée
    IF OLD.statut = 'terminee' AND NEW.statut <> 'terminee'
       AND EXISTS (SELECT 1 FROM avis WHERE id_location = OLD.id_location) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG23 : une location notée doit rester terminée';
    END IF;
END$$

-- RG20 (suite) : changer le propriétaire d'un objet ne doit pas créer
-- une location où le propriétaire loue son propre objet.
CREATE TRIGGER trg_objet_bu_proprietaire
BEFORE UPDATE ON objet
FOR EACH ROW
BEGIN
    IF NEW.id_membre <> OLD.id_membre AND EXISTS (
            SELECT 1 FROM location
            WHERE id_objet = NEW.id_objet AND id_locataire = NEW.id_membre) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG20 : le nouveau propriétaire a déjà loué cet objet';
    END IF;
END$$

-- RG23 : un avis n'est possible que sur une location terminée
CREATE TRIGGER trg_avis_bi_location_terminee
BEFORE INSERT ON avis
FOR EACH ROW
BEGIN
    IF (SELECT statut FROM location WHERE id_location = NEW.id_location) <> 'terminee' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'RG23 : un avis n''est possible que sur une location terminée';
    END IF;
END$$

DELIMITER ;
