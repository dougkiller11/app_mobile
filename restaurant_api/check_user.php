<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

try {
    // Récupérer les données POST
    $data = json_decode(file_get_contents('php://input'), true);
    $email = $data['email'] ?? '';

    if (empty($email)) {
        echo json_encode([
            'exists' => false,
            'role' => null,
            'message' => 'Email non fourni'
        ]);
        exit();
    }

    // Connexion à la base de données
    $conn = getConnection();

    // Vérifier si l'utilisateur existe et récupérer son rôle
    $stmt = $conn->prepare('SELECT role FROM users WHERE email = ?');
    $stmt->execute([$email]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($result) {
        echo json_encode([
            'exists' => true,
            'role' => $result['role'],
            'message' => 'Utilisateur trouvé'
        ]);
    } else {
        echo json_encode([
            'exists' => false,
            'role' => null,
            'message' => 'Utilisateur non trouvé'
        ]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'exists' => false,
        'role' => null,
        'message' => 'Erreur de base de données: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'exists' => false,
        'role' => null,
        'message' => 'Erreur: ' . $e->getMessage()
    ]);
} 