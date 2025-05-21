<?php
// Activer l'affichage des erreurs pour le débogage
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'config.php';

writeLog('=== NOUVELLE TENTATIVE DE CONNEXION ===');
writeLog('Méthode: ' . $_SERVER['REQUEST_METHOD']);
writeLog('Content-Type: ' . ($_SERVER['CONTENT_TYPE'] ?? 'non défini'));

// En-têtes CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=UTF-8');

// Gérer les requêtes OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        // Récupérer les données JSON
        $data = json_decode(file_get_contents('php://input'), true);
        writeLog('Données reçues: ' . json_encode($data));

        if (!isset($data['email']) || !isset($data['password'])) {
            throw new Exception('Email et mot de passe requis');
        }

        $email = $data['email'];
        $password = $data['password'];

        // Connexion à la base de données
        $conn = getConnection();
        writeLog('Connexion à la base de données établie');

        // Préparer la requête
        $stmt = $conn->prepare("SELECT id, email, full_name, role, password FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user && password_verify($password, $user['password'])) {
            // Générer un token unique
            $token = bin2hex(random_bytes(32));
            
            // Mettre à jour le token et la date de dernière connexion
            $updateStmt = $conn->prepare("UPDATE users SET token = ?, last_login = CURRENT_TIMESTAMP WHERE id = ?");
            $updateStmt->execute([$token, $user['id']]);

            // Préparer la réponse
            $response = [
                'success' => true,
                'message' => 'Connexion réussie',
                'token' => $token,
                'user' => [
                    'id' => $user['id'],
                    'email' => $user['email'],
                    'name' => $user['full_name'],
                    'role' => $user['role']
                ]
            ];

            writeLog('Connexion réussie pour: ' . $email);
            echo json_encode($response);
        } else {
            writeLog('Échec de connexion pour: ' . $email);
            throw new Exception('Email ou mot de passe incorrect');
        }

    } catch (Exception $e) {
        writeLog('ERREUR: ' . $e->getMessage());
        http_response_code(200); // On garde 200 pour gérer l'erreur côté client
        echo json_encode([
            'success' => false,
            'message' => $e->getMessage()
        ]);
    }
} else {
    writeLog('Méthode non autorisée: ' . $_SERVER['REQUEST_METHOD']);
    echo json_encode([
        'success' => false,
        'message' => 'Méthode non autorisée'
    ]);
}
?> 