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

// Récupérer le token
$headers = getallheaders();
$headers = array_change_key_case($headers, CASE_LOWER); // Normalise en minuscules
$token = null;

if (isset($headers['authorization'])) {
    $auth_header = $headers['authorization'];
    if (preg_match('/Bearer\s+(\S+)/i', $auth_header, $matches)) {
        $token = $matches[1];
    }
}

error_log("Token reçu dans check_token.php : " . ($token ?? 'null'));

try {
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    if (!$token) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token manquant']);
        exit();
    }
    
    // Vérifier le token dans la base de données
    $stmt = $pdo->prepare("SELECT * FROM users WHERE token = ?");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        error_log("Token valide pour l'utilisateur: " . $user['email']);
        echo json_encode([
            'success' => true,
            'message' => 'Token valide',
            'user' => [
                'id' => $user['id'],
                'email' => $user['email'],
                'role' => $user['role']
            ]
        ]);
    } else {
        error_log("Token invalide: " . $token);
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token invalide']);
    }
} catch(PDOException $e) {
    error_log("Erreur de base de données: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Erreur de base de données']);
}
?> 