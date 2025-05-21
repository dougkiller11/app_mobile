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

// Vérifier la méthode HTTP
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
    exit();
}

// Récupérer les données POST
$raw_data = file_get_contents('php://input');
error_log("=== DÉBUT DE LA CONNEXION ===");
error_log("Données reçues: " . $raw_data);

$data = json_decode($raw_data, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    error_log("Erreur de décodage JSON: " . json_last_error_msg());
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Données invalides']);
    exit();
}

$email = $data['email'] ?? '';
$password = $data['password'] ?? '';

error_log("Email: " . $email);

// Connexion à la base de données
try {
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Vérifier les identifiants
    $stmt = $pdo->prepare("SELECT id, email, full_name, role, password, token FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user) {
        error_log("Utilisateur trouvé: " . json_encode($user));
    } else {
        error_log("Aucun utilisateur trouvé avec cet email");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Email ou mot de passe incorrect']);
        exit();
    }
    
    if (password_verify($password, $user['password'])) {
        // Générer un nouveau token
        $token = bin2hex(random_bytes(32));
        error_log("Nouveau token généré: " . $token);
        
        // Mettre à jour le token et last_login dans la base de données
        $updateStmt = $pdo->prepare("UPDATE users SET token = ?, last_login = CURRENT_TIMESTAMP WHERE id = ?");
        $updateStmt->execute([$token, $user['id']]);
        error_log("Token et last_login mis à jour dans la base de données");
        
        // Vérifier que le token a bien été mis à jour
        $checkStmt = $pdo->prepare("SELECT token, last_login FROM users WHERE id = ?");
        $checkStmt->execute([$user['id']]);
        $updatedUser = $checkStmt->fetch(PDO::FETCH_ASSOC);
        error_log("Token vérifié dans la base de données: " . $updatedUser['token']);
        error_log("Dernière connexion: " . $updatedUser['last_login']);
        
        // Retourner les informations de l'utilisateur
        $response = [
            'success' => true,
            'message' => 'Connexion réussie',
            'token' => $token,
            'user' => [
                'id' => $user['id'],
                'email' => $user['email'],
                'full_name' => $user['full_name'],
                'role' => $user['role']
            ]
        ];
        error_log("Réponse envoyée: " . json_encode($response));
        echo json_encode($response);
    } else {
        error_log("Mot de passe incorrect");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Email ou mot de passe incorrect']);
    }
    
} catch(PDOException $e) {
    error_log("Erreur de base de données: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
}
error_log("=== FIN DE LA CONNEXION ===");
?> 