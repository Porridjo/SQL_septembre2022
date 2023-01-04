import java.sql.*;
import java.util.Scanner;

public class GestionCommandes {

    private String url="jdbc:postgresql://localhost:5432/" +
            "?user=postgres&password=postgres";
    private PreparedStatement ps;
    private Connection conn=null;

    public GestionCommandes() {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }

        try {
            conn= DriverManager.getConnection(url);
        } catch (SQLException e) {
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }

        try {
            ps= conn.prepareStatement("SELECT id_commande, date_commande, type_livraison, nb_articles_commandes\n" +
                    "FROM exam2022.vue\n" +
                    "WHERE client = ? AND type_livraison = 'livraison'\n" +
                    "ORDER BY date_commande");

        } catch (SQLException e) {
            System.out.println("Erreur avec les requêtes SQL !");
            close();
            System.exit(1);
        }
    }

    private void afficherCommande(String client) {
        try {
            ps.setString(1, client);
            try (ResultSet rs=ps.executeQuery()) {
                if (!rs.next()) {
                    System.out.println("Aucun client de ce nom ou aucune commande de type \"livraison\" à ce nom");
                } else {
                    do {
                        System.out.println("Commande: " + rs.getInt(1) +
                                ", Date de la commande: " + rs.getString(2) +
                                ", Type de livraison: " + rs.getString(3)  +
                                ", Nombre d'articles commandés: " + rs.getString(4));
                    } while(rs.next());
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public void close() {
        try {
            conn.close();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    public static void main(String[] args) {
        GestionCommandes gestionCommandes = new GestionCommandes();
        System.out.println("Introduisez un nom de client : ");
        Scanner scanner = new Scanner(System.in);
        String client = scanner.nextLine();
        gestionCommandes.afficherCommande(client);
        gestionCommandes.close();
    }

}
