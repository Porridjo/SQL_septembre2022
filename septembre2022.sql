DROP SCHEMA IF EXISTS exam2022 CASCADE;
CREATE SCHEMA exam2022;

CREATE TABLE exam2022.articles (
  id_article SERIAL PRIMARY KEY,
  nom CHARACTER VARYING(100) NOT NULL CHECK(nom <> ''),
  prix INTEGER NOT NULL CHECK(prix >= 0),
  poids INTEGER NOT NULL CHECK(poids > 0),
  quantite_maximale INTEGER CHECK(quantite_maximale > 0)
);

CREATE TABLE exam2022.commandes (
  id_commande SERIAL PRIMARY KEY,
  client CHARACTER VARYING(100) NOT NULL CHECK(client <> ''),
  date_commande DATE NOT NULL,
  type_livraison CHARACTER VARYING(20) NOT NULL CHECK(type_livraison = 'livraison' OR type_livraison = 'à emporter'),
  poids INTEGER NOT NULL DEFAULT 0 CHECK(poids >= 0)
);

CREATE TABLE exam2022.lignes_de_commande (
  commande INTEGER REFERENCES exam2022.commandes(id_commande) NOT NULL,
  article INTEGER REFERENCES exam2022.articles(id_article) NOT NULL,
  quantite INTEGER NOT NULL CHECK(quantite > 0),
  PRIMARY KEY(commande, article)
);

CREATE OR REPLACE FUNCTION exam2022.ajouterArticleAuPanier(_commande INTEGER, _article INTEGER) RETURNS INTEGER AS $$

BEGIN

  IF EXISTS(SELECT * FROM exam2022.lignes_de_commande WHERE commande = _commande AND article = _article)
  THEN
    UPDATE exam2022.lignes_de_commande SET quantite = quantite + 1 WHERE commande = _commande AND article = _article;
  ELSE
    INSERT INTO exam2022.lignes_de_commande VALUES (_commande, _article, 1);
  END IF;

  RETURN (SELECT COUNT(DISTINCT article)
          FROM exam2022.lignes_de_commande s1
          WHERE EXISTS (
            SELECT *
            FROM exam2022.lignes_de_commande s2
            WHERE s1.article = s2.article
              AND s1.commande <> s2.commande
            )
          );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION exam2022.verifierLignes() RETURNS TRIGGER AS $$
DECLARE
  _type CHARACTER VARYING(20);
  _article RECORD;
BEGIN
  SELECT quantite_maximale, prix, poids FROM exam2022.articles WHERE id_article = NEW.article INTO _article;
  IF ((SELECT quantite FROM exam2022.lignes_de_commande WHERE commande = NEW.commande AND article = NEW.article) + 1 >_article.quantite_maximale)
  THEN raise 'quantité maximale autorisée dépassée';
  END IF;

  SELECT type_livraison FROM exam2022.commandes WHERE id_commande = NEW.commande INTO _type;
  IF (_type = 'livraison' AND (SELECT SUM(a.prix*l.quantite) FROM exam2022.articles a, exam2022.lignes_de_commande l WHERE a.id_article = l.article AND commande = NEW.commande) + _article.prix > 1000)
  THEN raise 'prix total de la commande dépasse 1000 euros';
  END IF;

  UPDATE exam2022.commandes SET poids = poids + _article.poids WHERE id_commande = NEW.commande;
  RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verifierLignesTrigger BEFORE INSERT OR UPDATE ON exam2022.lignes_de_commande
    FOR EACH ROW EXECUTE PROCEDURE exam2022.verifierLignes();


INSERT INTO exam2022.articles VALUES (DEFAULT, 'article1', 100, 10, NULL);
INSERT INTO exam2022.articles VALUES (DEFAULT, 'article2', 400, 10, NULL);
INSERT INTO exam2022.articles VALUES (DEFAULT, 'article3', 10, 10, 2);
INSERT INTO exam2022.commandes VALUES (DEFAULT, 'David', '01/12/2022', 'livraison', DEFAULT);
INSERT INTO exam2022.commandes VALUES (DEFAULT, 'Charles', '01/12/2022', 'livraison', DEFAULT);
INSERT INTO exam2022.commandes VALUES (DEFAULT, 'Didier', '01/12/2022', 'à emporter', DEFAULT);
INSERT INTO exam2022.commandes VALUES (DEFAULT, 'David', '02/12/2022', 'livraison', DEFAULT);
INSERT INTO exam2022.commandes VALUES (DEFAULT, 'David', '02/12/2022', 'à emporter', DEFAULT);

/* cas quantité maximal dépassé*/
SELECT exam2022.ajouterArticleAuPanier(1,3);
SELECT exam2022.ajouterArticleAuPanier(1,3);
-- SELECT exam2022.ajouterArticleAuPanier(1,3);

/* cas prix total > 1000 pour commande de type livraison */
SELECT exam2022.ajouterArticleAuPanier(1,2);
SELECT exam2022.ajouterArticleAuPanier(1,2);
SELECT exam2022.ajouterArticleAuPanier(1,1);
--SELECT exam2022.ajouterArticleAuPanier(1,1);

CREATE OR REPLACE VIEW exam2022.vue (id_commande, date_commande, nb_articles_commandes, client)
AS SELECT c.id_commande,
  c.date_commande,
  COALESCE(COUNT(l.article), 0),
  c.client
  FROM exam2022.commandes c
    LEFT OUTER JOIN exam2022.lignes_de_commande l ON c.id_commande = l.commande
  WHERE c.type_livraison = 'livraison'
  GROUP BY c.id_commande, c.date_commande, c.client;

/*
SELECT id_commande, date_commande, nb_articles_commandes
FROM exam2022.vue
WHERE client = 'David'
ORDER BY date_commande
 */