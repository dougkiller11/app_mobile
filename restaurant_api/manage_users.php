<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Autoriser les requêtes CORS
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
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

    // Récupérer les données de la requête
    $data = json_decode(file_get_contents('php://input'), true);
    $action = $_GET['action'] ?? '';

    switch ($_SERVER['REQUEST_METHOD']) {
        case 'GET':
            // Lire les utilisateurs
            if ($action === 'get_all') {
                $stmt = $pdo->query("SELECT id, email, full_name, role, created_at, last_login FROM users ORDER BY role, email");
                $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
                echo json_encode(['success' => true, 'users' => $users]);
            } elseif ($action === 'get_one' && isset($_GET['id'])) {
                $stmt = $pdo->prepare("SELECT id, email, full_name, role, created_at, last_login FROM users WHERE id = ?");
                $stmt->execute([$_GET['id']]);
                $user = $stmt->fetch(PDO::FETCH_ASSOC);
                if ($user) {
                    echo json_encode(['success' => true, 'user' => $user]);
                } else {
                    echo json_encode(['success' => false, 'message' => 'Utilisateur non trouvé']);
                }
            }
            break;

        case 'POST':
            // Créer un nouvel utilisateur
            if (!isset($data['email']) || !isset($data['password']) || !isset($data['full_name']) || !isset($data['role'])) {
                throw new Exception('Tous les champs sont requis');
            }

            // Vérifier si l'email existe déjà
            $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
            $stmt->execute([$data['email']]);
            if ($stmt->fetch()) {
                throw new Exception('Cet email est déjà utilisé');
            }

            // Créer l'utilisateur
            $stmt = $pdo->prepare("INSERT INTO users (email, password, full_name, role) VALUES (?, ?, ?, ?)");
            $hashedPassword = password_hash($data['password'], PASSWORD_DEFAULT);
            $stmt->execute([$data['email'], $hashedPassword, $data['full_name'], $data['role']]);
            
            echo json_encode([
                'success' => true,
                'message' => 'Utilisateur créé avec succès',
                'user_id' => $pdo->lastInsertId()
            ]);
            break;

        case 'PUT':
            // Mettre à jour un utilisateur
            if (!isset($data['id'])) {
                throw new Exception('ID utilisateur requis');
            }

            $updates = [];
            $params = [];

            if (isset($data['email'])) {
                $updates[] = "email = ?";
                $params[] = $data['email'];
            }
            if (isset($data['password'])) {
                $updates[] = "password = ?";
                $params[] = password_hash($data['password'], PASSWORD_DEFAULT);
            }
            if (isset($data['full_name'])) {
                $updates[] = "full_name = ?";
                $params[] = $data['full_name'];
            }
            if (isset($data['role'])) {
                $updates[] = "role = ?";
                $params[] = $data['role'];
            }

            if (empty($updates)) {
                throw new Exception('Aucune donnée à mettre à jour');
            }

            $params[] = $data['id'];
            $sql = "UPDATE users SET " . implode(", ", $updates) . " WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute($params);

            echo json_encode([
                'success' => true,
                'message' => 'Utilisateur mis à jour avec succès'
            ]);
            break;

        case 'DELETE':
            // Supprimer un utilisateur
            if (!isset($_GET['id'])) {
                throw new Exception('ID utilisateur requis');
            }

            $stmt = $pdo->prepare("DELETE FROM users WHERE id = ?");
            $stmt->execute([$_GET['id']]);

            if ($stmt->rowCount() > 0) {
                echo json_encode([
                    'success' => true,
                    'message' => 'Utilisateur supprimé avec succès'
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Utilisateur non trouvé'
                ]);
            }
            break;

        default:
            throw new Exception('Méthode non supportée');
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?> 