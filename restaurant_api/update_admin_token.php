<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

try {
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Générer un nouveau token
    $token = bin2hex(random_bytes(32));
    
    // Mettre à jour le token de l'administrateur
    $stmt = $pdo->prepare("UPDATE users SET token = ? WHERE email = ? AND role = 'admin'");
    $stmt->execute([$token, 'admin@example.com']);
    
    if ($stmt->rowCount() > 0) {
        echo "Token mis à jour avec succès pour admin@example.com\n";
        echo "Nouveau token: " . $token . "\n";
    } else {
        echo "Aucun administrateur trouvé avec cet email\n";
    }
    
} catch(PDOException $e) {
    echo "Erreur : " . $e->getMessage() . "\n";
}
?> 