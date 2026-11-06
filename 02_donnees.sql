-- =====================================================================
-- Tiroir - 02_donnees.sql : jeu d'essai (au moins 5 lignes par table)
-- A exécuter après 01_schema.sql.
-- Les triggers du schéma s'appliquent : le jeu respecte toutes les règles.
-- =====================================================================

USE tiroir;
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- MEMBRE (6)
-- ---------------------------------------------------------------------
INSERT INTO membre (id_membre, nom, prenom, pseudo, email, telephone, code_postal) VALUES
(1, 'Dupont',  'Camille', 'camille_d', 'camille.dupont@example.com', '0601020301', '75011'),
(2, 'Martin',  'Lucas',   'lucas_m',   'lucas.martin@example.com',   '0601020302', '92000'),
(3, 'Bernard', 'Sophie',  'sophie_b',  'sophie.bernard@example.com', '0601020303', '69003'),
(4, 'Petit',   'Karim',   'karim_p',   'karim.petit@example.com',    '0601020304', '13001'),
(5, 'Moreau',  'Léa',     'lea_m',     'lea.moreau@example.com',     '0601020305', '31000'),
(6, 'Roux',    'Thomas',  'thomas_r',  'thomas.roux@example.com',    '0601020306', '33000');

-- ---------------------------------------------------------------------
-- CATEGORIE (8) : 4 catégories racines + 4 sous-catégories
-- ---------------------------------------------------------------------
INSERT INTO categorie (id_categorie, nom, id_categorie_parent) VALUES
(1, 'Bricolage',            NULL),
(2, 'Camping',              NULL),
(3, 'Cuisine',              NULL),
(4, 'Jardinage',            NULL),
(5, 'Perceuses',            1),
(6, 'Tentes',               2),
(7, 'Appareils à raclette', 3),
(8, 'Tondeuses',            4);

-- ---------------------------------------------------------------------
-- OBJET (11) : l'objet 6 est en pause (actif = 0)
-- ---------------------------------------------------------------------
INSERT INTO objet (id_objet, titre, description, prix_jour, caution, etat, actif, id_membre, id_categorie) VALUES
(1,  'Perceuse à percussion Bosch',  'Perceuse 18 V avec 2 batteries et coffret de forets.',  8.00,  50.00, 'très bon', 1, 1, 5),
(2,  'Visseuse Makita',              'Visseuse sans fil, chargeur inclus.',                    6.00,  40.00, 'bon',      1, 1, 5),
(3,  'Tente 4 places Quechua',       'Tente familiale, montage en 10 minutes.',               12.00,  80.00, 'neuf',     1, 2, 6),
(4,  'Tente 2 secondes 2 places',    'Tente à ouverture instantanée, idéale pour un week-end.', 7.50, 40.00, 'bon',     1, 2, 6),
(5,  'Appareil à raclette 8 personnes', 'Raclette avec 8 poêlons et 2 plateaux grill.',         5.00,  30.00, 'très bon', 1, 3, 7),
(6,  'Raclette 4 personnes',         'Petit modèle, remis à neuf prochainement.',              4.00,  20.00, 'usé',      0, 3, 7),
(7,  'Tondeuse thermique',           'Tondeuse tractée 46 cm, bac de ramassage.',             15.00, 100.00, 'bon',      1, 4, 8),
(8,  'Ponceuse excentrique',         'Ponceuse 300 W avec 20 disques de ponçage.',             9.00,  60.00, 'très bon', 1, 4, 1),
(9,  'Réchaud de camping',           'Réchaud à gaz deux feux, cartouche non fournie.',        3.50,  15.00, 'usé',      1, 5, 2),
(10, 'Mixeur plongeant',             'Mixeur 800 W avec bol doseur.',                          3.00,  15.00, 'neuf',     1, 6, 3),
(11, 'Taille-haie électrique',       'Taille-haie 60 cm, câble 10 m fourni.',                 10.00,  50.00, 'bon',      1, 5, 4);

-- ---------------------------------------------------------------------
-- PHOTO (14) : numérotées 1, 2, 3... par objet
-- ---------------------------------------------------------------------
INSERT INTO photo (id_objet, numero, url) VALUES
(1, 1, 'https://img.tiroir.example/objets/1/1.jpg'),
(1, 2, 'https://img.tiroir.example/objets/1/2.jpg'),
(1, 3, 'https://img.tiroir.example/objets/1/3.jpg'),
(2, 1, 'https://img.tiroir.example/objets/2/1.jpg'),
(3, 1, 'https://img.tiroir.example/objets/3/1.jpg'),
(3, 2, 'https://img.tiroir.example/objets/3/2.jpg'),
(4, 1, 'https://img.tiroir.example/objets/4/1.jpg'),
(5, 1, 'https://img.tiroir.example/objets/5/1.jpg'),
(5, 2, 'https://img.tiroir.example/objets/5/2.jpg'),
(7, 1, 'https://img.tiroir.example/objets/7/1.jpg'),
(7, 2, 'https://img.tiroir.example/objets/7/2.jpg'),
(8, 1, 'https://img.tiroir.example/objets/8/1.jpg'),
(9, 1, 'https://img.tiroir.example/objets/9/1.jpg'),
(10, 1, 'https://img.tiroir.example/objets/10/1.jpg');

-- ---------------------------------------------------------------------
-- LOCATION (12) : prix_total = prix_jour x nombre de jours (bornes incluses)
-- 6 terminées, 2 acceptées (sans chevauchement), 2 demandées, 1 refusée, 1 annulée.
-- Aucune location sur son propre objet.
-- ---------------------------------------------------------------------
INSERT INTO location (id_location, date_debut, date_fin, prix_total, statut, id_objet, id_locataire) VALUES
(1,  '2026-03-02', '2026-03-04', 24.00, 'terminee', 1, 2),
(2,  '2026-06-10', '2026-06-14', 60.00, 'terminee', 3, 1),
(3,  '2026-02-14', '2026-02-15', 10.00, 'terminee', 5, 4),
(4,  '2026-04-18', '2026-04-18', 15.00, 'terminee', 7, 5),
(5,  '2026-05-01', '2026-05-03', 24.00, 'terminee', 1, 3),
(6,  '2026-07-05', '2026-07-08', 36.00, 'terminee', 8, 2),
(7,  '2026-12-20', '2026-12-27', 96.00, 'acceptee', 3, 5),
(8,  '2026-12-26', '2026-12-30', 60.00, 'demandee', 3, 4),
(9,  '2026-11-20', '2026-11-22',  9.00, 'demandee', 10, 1),
(10, '2026-11-10', '2026-11-12', 18.00, 'refusee',  2, 3),
(11, '2026-08-01', '2026-08-03', 22.50, 'annulee',  4, 6),
(12, '2026-11-15', '2026-11-16',  7.00, 'acceptee', 9, 6);

-- ---------------------------------------------------------------------
-- AVIS (9) : uniquement sur des locations terminées, au plus un avis par côté
-- ---------------------------------------------------------------------
INSERT INTO avis (id_location, sens, note, commentaire, date_avis) VALUES
(1, 'LOCATAIRE',    5, 'Perceuse parfaite, très puissante.',               '2026-03-05 10:12:00'),
(1, 'PROPRIETAIRE', 4, 'Locataire ponctuel, matériel rendu propre.',       '2026-03-05 18:40:00'),
(2, 'LOCATAIRE',    4, 'Tente neuve et facile à monter.',                  '2026-06-15 09:00:00'),
(2, 'PROPRIETAIRE', 5, NULL,                                               '2026-06-15 20:15:00'),
(3, 'LOCATAIRE',    3, 'Fonctionne bien, un poêlon était abîmé.',          '2026-02-16 11:30:00'),
(4, 'LOCATAIRE',    5, 'Tondeuse efficace, remise en main propre.',        '2026-04-19 08:45:00'),
(4, 'PROPRIETAIRE', 5, 'Parfait, je recommande.',                          '2026-04-19 12:00:00'),
(5, 'LOCATAIRE',    4, NULL,                                               '2026-05-04 17:20:00'),
(6, 'PROPRIETAIRE', 2, 'Rendue en retard et poussiéreuse.',                '2026-07-09 19:05:00');

-- ---------------------------------------------------------------------
-- FAVORI (8) : avec la date d'ajout
-- ---------------------------------------------------------------------
INSERT INTO favori (id_membre, id_objet, date_ajout) VALUES
(1, 3,  '2026-05-20 14:03:00'),
(1, 5,  '2026-06-02 09:30:00'),
(2, 7,  '2026-03-12 19:45:00'),
(3, 1,  '2026-04-25 08:10:00'),
(4, 3,  '2026-10-01 21:00:00'),
(5, 3,  '2026-09-14 12:25:00'),
(5, 10, '2026-10-18 16:40:00'),
(6, 9,  '2026-10-30 07:55:00');
