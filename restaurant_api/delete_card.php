<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json');

require_once 'db_connect.php';
require_once 'auth.php';

// Vérifier si l'utilisateur est authentifié
$user = authenticate();
if (!$user) {
    echo json_encode(['success' => false, 'message' => 'Non autorisé']);
    exit;
}

// Récupérer l'ID de la carte
$cardId = $_GET['id'] ?? null;
if (!$cardId) {
    echo json_encode(['success' => false, 'message' => 'ID de la carte manquant']);
    exit;
}

try {
    // Vérifier si la carte appartient à l'utilisateur
    $stmt = $pdo->prepare("SELECT is_default FROM cards WHERE id = ? AND user_id = ?");
    $stmt->execute([$cardId, $user['id']]);
    $card = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$card) {
        echo json_encode(['success' => false, 'message' => 'Carte non trouvée']);
        exit;
    }

    // Si c'est la carte par défaut, ne pas permettre la suppression
    if ($card['is_default']) {
        echo json_encode(['success' => false, 'message' => 'Impossible de supprimer la carte par défaut']);
        exit;
    }

    // Supprimer la carte
    $stmt = $pdo->prepare("DELETE FROM cards WHERE id = ? AND user_id = ?");
    $stmt->execute([$cardId, $user['id']]);

    echo json_encode([
        'success' => true,
        'message' => 'Carte supprimée avec succès'
    ]);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la suppression de la carte: ' . $e->getMessage()
    ]);
}
?> 