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

// Gérer les requêtes OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

try {
    // Connexion à la base de données
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Récupérer tous les utilisateurs avec leurs informations de base
    $stmt = $pdo->query("SELECT id, email, full_name, role, created_at FROM users ORDER BY role DESC, created_at DESC");
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
        'admins' => array_values($admins),
        'clients' => array_values($clients),
        'total' => count($users)
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
}
?> 