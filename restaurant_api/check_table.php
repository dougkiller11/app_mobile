<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Autoriser les requêtes CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

try {
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Vérifier la structure de la table users
    $stmt = $pdo->query("DESCRIBE users");
    echo "Structure de la table users:\n";
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        print_r($row);
    }
    
    // Vérifier si la colonne token existe
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'token'");
    if ($stmt->rowCount() == 0) {
        echo "\nLa colonne token n'existe pas. Ajout de la colonne...\n";
        $pdo->exec("ALTER TABLE users ADD COLUMN token VARCHAR(255)");
        echo "Colonne token ajoutée avec succès.\n";
    } else {
        echo "\nLa colonne token existe déjà.\n";
    }
    
    // Afficher quelques utilisateurs pour vérifier
    $stmt = $pdo->query("SELECT id, email, role, token FROM users LIMIT 5");
    echo "\nExemple d'utilisateurs:\n";
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        print_r($row);
    }
    
} catch(PDOException $e) {
    echo "Erreur: " . $e->getMessage();
}
?> 