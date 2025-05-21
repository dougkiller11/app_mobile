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

if (!isset($data['id'])) {
    http_response_code(400);
    echo json_encode(['error' => 'ID utilisateur manquant']);
    exit;
}

try {
    // Vérifier si l'utilisateur existe
    $stmt = $pdo->prepare("SELECT role FROM users WHERE id = ?");
    $stmt->execute([$data['id']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(404);
        echo json_encode(['error' => 'Utilisateur non trouvé']);
        exit;
    }

    // Empêcher la suppression du dernier admin
    if ($user['role'] === 'admin') {
        $stmt = $pdo->query("SELECT COUNT(*) FROM users WHERE role = 'admin'");
        $adminCount = $stmt->fetchColumn();
        if ($adminCount <= 1) {
            http_response_code(400);
            echo json_encode(['error' => 'Impossible de supprimer le dernier administrateur']);
            exit;
        }
    }

    // Supprimer l'utilisateur
    $stmt = $pdo->prepare("DELETE FROM users WHERE id = ?");
    $stmt->execute([$data['id']]);
    
    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => true, 'message' => 'Utilisateur supprimé avec succès']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la suppression de l\'utilisateur']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Erreur lors de la suppression de l\'utilisateur: ' . $e->getMessage()]);
}
?> 