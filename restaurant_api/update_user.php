<?php
header('Content-Type: application/json');
require_once 'config.php';
require_once 'check_admin.php';

// Vérifier si l'utilisateur est admin
if (!isAdmin()) {
    http_response_code(403);
    echo json_encode(['error' => 'Accès non autorisé']);
    exit;
}

$data = json_decode(file_get_contents('php://input'), true);

if (!isset($data['id']) || !isset($data['email']) || !isset($data['name']) || !isset($data['role'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Données manquantes']);
    exit;
}

try {
    // Vérifier si l'email existe déjà pour un autre utilisateur
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
    $stmt->execute([$data['email'], $data['id']]);
    if ($stmt->rowCount() > 0) {
        http_response_code(400);
        echo json_encode(['error' => 'Cet email est déjà utilisé par un autre utilisateur']);
        exit;
    }

    // Mettre à jour l'utilisateur
    $stmt = $pdo->prepare("UPDATE users SET email = ?, full_name = ?, role = ? WHERE id = ?");
    $stmt->execute([$data['email'], $data['name'], $data['role'], $data['id']]);
    
    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => true, 'message' => 'Utilisateur mis à jour avec succès']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Aucune modification effectuée']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Erreur lors de la mise à jour de l\'utilisateur: ' . $e->getMessage()]);
}
?> 