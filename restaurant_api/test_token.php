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

// Connexion à la base de données
try {
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Vérifier la structure de la table users
    $stmt = $pdo->query("DESCRIBE users");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Structure de la table users:\n";
    print_r($columns);
    
    // Vérifier si la colonne token existe
    $hasTokenColumn = false;
    foreach ($columns as $column) {
        if ($column['Field'] === 'token') {
            $hasTokenColumn = true;
            break;
        }
    }
    
    if (!$hasTokenColumn) {
        echo "\nLa colonne token n'existe pas. Création...\n";
        $pdo->exec("ALTER TABLE users ADD COLUMN token VARCHAR(255)");
        echo "Colonne token créée avec succès.\n";
    }
    
    // Générer un token de test
    $testToken = bin2hex(random_bytes(32));
    echo "\nToken de test généré: " . $testToken . "\n";
    
    // Mettre à jour un utilisateur de test (le premier trouvé)
    $stmt = $pdo->query("SELECT id FROM users LIMIT 1");
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        $updateStmt = $pdo->prepare("UPDATE users SET token = ? WHERE id = ?");
        $updateStmt->execute([$testToken, $user['id']]);
        echo "Token mis à jour pour l'utilisateur ID: " . $user['id'] . "\n";
        
        // Vérifier que le token a bien été mis à jour
        $checkStmt = $pdo->prepare("SELECT token FROM users WHERE id = ?");
        $checkStmt->execute([$user['id']]);
        $updatedUser = $checkStmt->fetch(PDO::FETCH_ASSOC);
        echo "Token vérifié dans la base de données: " . $updatedUser['token'] . "\n";
    } else {
        echo "Aucun utilisateur trouvé dans la base de données.\n";
    }
    
} catch(PDOException $e) {
    echo "Erreur de base de données: " . $e->getMessage() . "\n";
}
?> 