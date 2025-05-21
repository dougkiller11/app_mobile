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

echo "Début du script\n";

try {
    echo "Tentative de connexion à la base de données...\n";
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "Connexion à la base de données réussie\n";
    
    // Récupérer tous les utilisateurs avec leurs tokens
    echo "Récupération des utilisateurs...\n";
    $stmt = $pdo->query("SELECT id, email, role, token FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Nombre d'utilisateurs trouvés : " . count($users) . "\n";
    
    echo json_encode([
        'success' => true,
        'users' => $users,
        'debug_info' => [
            'php_version' => PHP_VERSION,
            'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
            'database_connection' => 'Success'
        ]
    ], JSON_PRETTY_PRINT);
    
} catch(PDOException $e) {
    echo "Erreur de base de données : " . $e->getMessage() . "\n";
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de base de données: ' . $e->getMessage(),
        'debug_info' => [
            'php_version' => PHP_VERSION,
            'server_software' => $_SERVER['SERVER_SOFTWARE'] ?? 'Unknown',
            'error_details' => $e->getMessage()
        ]
    ]);
}
?> 