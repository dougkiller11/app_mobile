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

// Récupérer les données
$data = json_decode(file_get_contents('php://input'), true);
$cardId = $data['card_id'] ?? null;

if (!$cardId) {
    echo json_encode(['success' => false, 'message' => 'ID de la carte manquant']);
    exit;
}

try {
    // Vérifier si la carte appartient à l'utilisateur
    $stmt = $pdo->prepare("SELECT id FROM cards WHERE id = ? AND user_id = ?");
    $stmt->execute([$cardId, $user['id']]);
    if (!$stmt->fetch()) {
        echo json_encode(['success' => false, 'message' => 'Carte non trouvée']);
        exit;
    }

    // Démarrer une transaction
    $pdo->beginTransaction();

    // Réinitialiser toutes les cartes de l'utilisateur
    $stmt = $pdo->prepare("UPDATE cards SET is_default = 0 WHERE user_id = ?");
    $stmt->execute([$user['id']]);

    // Définir la nouvelle carte par défaut
    $stmt = $pdo->prepare("UPDATE cards SET is_default = 1 WHERE id = ? AND user_id = ?");
    $stmt->execute([$cardId, $user['id']]);

    // Valider la transaction
    $pdo->commit();

    echo json_encode([
        'success' => true,
        'message' => 'Carte par défaut mise à jour avec succès'
    ]);
} catch (PDOException $e) {
    // Annuler la transaction en cas d'erreur
    $pdo->rollBack();
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de la mise à jour de la carte par défaut: ' . $e->getMessage()
    ]);
}
?> 