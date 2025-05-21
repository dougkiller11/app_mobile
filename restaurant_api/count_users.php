<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Autoriser les requêtes CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

try {
    // Connexion à la base de données
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Récupérer tous les utilisateurs avec leurs détails
    $stmt = $pdo->query("SELECT id, email, full_name, role, created_at FROM users ORDER BY role, email");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Séparer les utilisateurs par rôle
    $admins = array_filter($users, function($user) {
        return $user['role'] === 'admin';
    });
    
    $clients = array_filter($users, function($user) {
        return $user['role'] === 'client';
    });
    
    echo json_encode([
        'success' => true,
        'counts' => [
            'admins' => count($admins),
            'clients' => count($clients),
            'total' => count($users)
        ],
        'admins' => array_values($admins),
        'clients' => array_values($clients)
    ], JSON_PRETTY_PRINT);
    
} catch(PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
}
?> 