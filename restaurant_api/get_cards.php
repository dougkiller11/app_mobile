<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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

try {
    $stmt = $pdo->prepare("SELECT * FROM cards WHERE user_id = ? ORDER BY is_default DESC, created_at DESC");
    $stmt->execute([$user['id']]);
    $cards = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Masquer les informations sensibles
    foreach ($cards as &$card) {
        $card['card_number'] = substr($card['card_number'], -4);
        $card['cvv'] = '***';
    }

    echo json_encode([
        'success' => true,
        'cards' => $cards
    ]);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la récupération des cartes: ' . $e->getMessage()
    ]);
}
?> 