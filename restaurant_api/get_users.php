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
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Méthode non autorisée']);
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

error_log("Token extrait dans get_users.php : " . ($token ?? 'null'));

try {
    $pdo = new PDO("mysql:host=localhost;dbname=restaurant_db", "root", "");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Vérifier le token et le rôle
    if (!$token) {
        error_log("Token manquant dans get_users.php");
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Token manquant']);
        exit();
    }

    $stmt = $pdo->prepare("SELECT role FROM users WHERE token = ?");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    error_log("Résultat de la vérification du token : " . json_encode($user));

    if (!$user) {
        error_log("Token invalide dans get_users.php : " . $token);
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Token invalide']);
        exit();
    }

    if ($user['role'] !== 'admin') {
        error_log("Utilisateur non admin tentant d'accéder à get_users.php : " . $user['role']);
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Accès réservé aux administrateurs']);
        exit();
    }

    // Récupérer tous les utilisateurs
    $stmt = $pdo->query("SELECT id, email, full_name, role, created_at FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    error_log("Nombre d'utilisateurs récupérés : " . count($users));

    echo json_encode([
        'success' => true,
        'users' => $users
    ]);
} catch (PDOException $e) {
    error_log("Erreur de base de données dans get_users.php : " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
}
?>
