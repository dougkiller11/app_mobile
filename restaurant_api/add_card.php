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

// Récupérer les données de la carte
$data = json_decode(file_get_contents('php://input'), true);

// Vérifier les champs requis
$required_fields = ['card_number', 'card_holder', 'expiry_date', 'cvv'];
foreach ($required_fields as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
        echo json_encode(['success' => false, 'message' => "Le champ $field est requis"]);
        exit;
    }
}

try {
    // Vérifier si c'est la première carte de l'utilisateur
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM cards WHERE user_id = ?");
    $stmt->execute([$user['id']]);
    $cardCount = $stmt->fetchColumn();
    
    // Si c'est la première carte, la définir comme carte par défaut
    $isDefault = $cardCount === 0;

    // Insérer la nouvelle carte
    $stmt = $pdo->prepare("
        INSERT INTO cards (user_id, card_number, card_holder, expiry_date, cvv, is_default, created_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ");

    $stmt->execute([
        $user['id'],
        $data['card_number'],
        $data['card_holder'],
        $data['expiry_date'],
        $data['cvv'],
        $isDefault
    ]);

    echo json_encode([
        'success' => true,
        'message' => 'Carte ajoutée avec succès',
        'card_id' => $pdo->lastInsertId()
    ]);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Erreur lors de l\'ajout de la carte: ' . $e->getMessage()
    ]);
}
?> 