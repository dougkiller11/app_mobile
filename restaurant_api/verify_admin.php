<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

try {
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Vérifier le token de l'administrateur
    $stmt = $pdo->prepare("SELECT id, email, role, token FROM users WHERE email = ? AND role = 'admin'");
    $stmt->execute(['admin@example.com']);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($admin) {
        echo "Informations de l'administrateur :\n";
        echo "ID: " . $admin['id'] . "\n";
        echo "Email: " . $admin['email'] . "\n";
        echo "Rôle: " . $admin['role'] . "\n";
        echo "Token: " . $admin['token'] . "\n";
        
        if ($admin['token']) {
            echo "\nLe token est valide et présent dans la base de données.\n";
            echo "Vous pouvez maintenant vous connecter avec ces identifiants :\n";
            echo "Email: admin@example.com\n";
            echo "Token: " . $admin['token'] . "\n";
        } else {
            echo "\nATTENTION: Le token est vide!\n";
        }
    } else {
        echo "Aucun administrateur trouvé avec cet email\n";
    }
    
} catch(PDOException $e) {
    echo "Erreur : " . $e->getMessage() . "\n";
}
?> 