<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "Test de connexion à la base de données...\n";

try {
    // Connexion à MySQL sans spécifier de base de données
    $pdo = new PDO("mysql:host=localhost", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "Connexion à MySQL réussie!\n";
    
    // Vérifier si la base de données existe
    $stmt = $pdo->query("SHOW DATABASES LIKE 'restaurant_db'");
    if ($stmt->rowCount() > 0) {
        echo "La base de données 'restaurant_db' existe.\n";
        
        // Se connecter à la base de données
        $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
        echo "Connexion à la base de données 'restaurant_db' réussie!\n";
        
        // Vérifier la table users
        $stmt = $pdo->query("SHOW TABLES LIKE 'users'");
        if ($stmt->rowCount() > 0) {
            echo "La table 'users' existe.\n";
            
            // Compter les utilisateurs par rôle
            $stmt = $pdo->query("SELECT role, COUNT(*) as count FROM users GROUP BY role");
            echo "\nNombre d'utilisateurs par rôle :\n";
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                echo $row['role'] . " : " . $row['count'] . " utilisateurs\n";
            }
            
            // Afficher tous les utilisateurs avec tous leurs détails
            $stmt = $pdo->query("SELECT * FROM users ORDER BY role, email");
            echo "\nListe complète des utilisateurs :\n";
            echo "----------------------------------------\n";
            while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
                echo "ID : " . $row['id'] . "\n";
                echo "Email : " . $row['email'] . "\n";
                echo "Nom complet : " . ($row['full_name'] ?? 'Non renseigné') . "\n";
                echo "Rôle : " . $row['role'] . "\n";
                echo "Date de création : " . $row['created_at'] . "\n";
                if (isset($row['last_login'])) {
                    echo "Dernière connexion : " . $row['last_login'] . "\n";
                }
                echo "----------------------------------------\n";
            }
        } else {
            echo "La table 'users' n'existe pas.\n";
        }
    } else {
        echo "La base de données 'restaurant_db' n'existe pas.\n";
    }
} catch(PDOException $e) {
    echo "Erreur : " . $e->getMessage() . "\n";
}
?> 