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
    
    // Liste des administrateurs à créer
    $admins = [
        ['email' => 'admin1@example.com', 'full_name' => 'Admin Un'],
        ['email' => 'admin2@example.com', 'full_name' => 'Admin Deux'],
        ['email' => 'admin3@example.com', 'full_name' => 'Admin Trois']
    ];
    
    // Liste des clients à créer
    $clients = [
        ['email' => 'client1@example.com', 'full_name' => 'Client Un'],
        ['email' => 'client2@example.com', 'full_name' => 'Client Deux'],
        ['email' => 'client3@example.com', 'full_name' => 'Client Trois'],
        ['email' => 'client4@example.com', 'full_name' => 'Client Quatre'],
        ['email' => 'client5@example.com', 'full_name' => 'Client Cinq']
    ];
    
    // Préparer la requête d'insertion
    $stmt = $pdo->prepare("INSERT INTO users (email, password, full_name, role) VALUES (?, ?, ?, ?)");
    
    // Ajouter les administrateurs
    foreach ($admins as $admin) {
        $hashedPassword = password_hash('admin123', PASSWORD_DEFAULT);
        $stmt->execute([$admin['email'], $hashedPassword, $admin['full_name'], 'admin']);
    }
    
    // Ajouter les clients
    foreach ($clients as $client) {
        $hashedPassword = password_hash('client123', PASSWORD_DEFAULT);
        $stmt->execute([$client['email'], $hashedPassword, $client['full_name'], 'client']);
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Utilisateurs de test créés avec succès',
        'admins_created' => count($admins),
        'clients_created' => count($clients)
    ]);
    
} catch(PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
}
?> 