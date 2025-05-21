<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Créer le dossier uploads s'il n'existe pas
$uploadDir = __DIR__ . '/uploads/';
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['image'])) {
    $file = $_FILES['image'];
    $fileName = uniqid() . '_' . basename($file['name']);
    $targetPath = $uploadDir . $fileName;

    // Vérifier le type de fichier
    $allowedTypes = ['image/jpeg', 'image/png', 'image/gif'];
    if (!in_array($file['type'], $allowedTypes)) {
        echo json_encode([
            'success' => false,
            'message' => 'Type de fichier non autorisé'
        ]);
        exit();
    }

    // Vérifier la taille (5MB max)
    if ($file['size'] > 5 * 1024 * 1024) {
        echo json_encode([
            'success' => false,
            'message' => 'Fichier trop volumineux (max 5MB)'
        ]);
        exit();
    }

    if (move_uploaded_file($file['tmp_name'], $targetPath)) {
        // Retourner l'URL de l'image
        $imageUrl = 'http://localhost/restaurant_api/uploads/' . $fileName;
        echo json_encode([
            'success' => true,
            'image_url' => $imageUrl
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Erreur lors du téléchargement'
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Aucune image reçue'
    ]);
} 