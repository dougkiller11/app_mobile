<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Autoriser les requêtes CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

// Gérer les requêtes OPTIONS pour le CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Vérifier que la requête est en POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
    exit();
}

// Récupérer les données brutes du corps de la requête
$raw_data = file_get_contents('php://input');
error_log("Données reçues: " . $raw_data);

// Décoder les données JSON
$data = json_decode($raw_data, true);
error_log("Données décodées: " . print_r($data, true));

// Vérifier si les données sont valides
if (!$data || !isset($data['email']) || !isset($data['password'])) {
    error_log("Données invalides ou manquantes");
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Données invalides']);
    exit();
}

// Connexion à la base de données
$host = 'localhost';
$dbname = 'restaurant_db';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    error_log("Connexion à la base de données réussie");
} catch (PDOException $e) {
    error_log("Erreur de connexion à la base de données: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur de connexion à la base de données']);
    exit();
}

// Vérifier les identifiants
$email = $data['email'];
$password = $data['password'];

error_log("Tentative de connexion pour l'email: " . $email);

// Vérifier si c'est l'admin local
if ($email === 'adminlocal@example.com' && $password === 'admin123') {
    error_log("Connexion admin locale réussie");
    $token = bin2hex(random_bytes(32));
    
    // Mettre à jour le token dans la base de données
    try {
        $stmt = $pdo->prepare("UPDATE users SET token = ? WHERE email = ?");
        $stmt->execute([$token, $email]);
        error_log("Token mis à jour dans la base de données");
    } catch (PDOException $e) {
        error_log("Erreur lors de la mise à jour du token: " . $e->getMessage());
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Connexion réussie',
        'token' => $token,
        'user' => [
            'id' => 1,
            'email' => $email,
            'role' => 'admin'
        ],
        'isAdmin' => true
    ]);
    exit();
}

// Si ce n'est pas l'admin local, vérifier dans la base de données
try {
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user && password_verify($password, $user['password'])) {
        $token = bin2hex(random_bytes(32));
        
        // Mettre à jour le token
        $updateStmt = $pdo->prepare("UPDATE users SET token = ? WHERE id = ?");
        $updateStmt->execute([$token, $user['id']]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Connexion réussie',
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'email' => $user['email'],
                'role' => $user['role']
            ],
            'isAdmin' => $user['role'] === 'admin'
        ]);
    } else {
        error_log("Identifiants incorrects pour l'email: " . $email);
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Email ou mot de passe incorrect']);
    }
} catch (PDOException $e) {
    error_log("Erreur lors de la vérification des identifiants: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la vérification des identifiants']);
}
?> 