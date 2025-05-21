<?php
require_once 'config.php';
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    $conn = getConnection();
    
    // Récupérer les données JSON
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data) {
        throw new Exception('Données invalides');
    }
    
    // Valider les données requises
    $required_fields = ['name', 'description', 'price', 'category', 'image_url'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            throw new Exception("Le champ '$field' est requis");
        }
    }
    
    // Préparer et exécuter la requête
    $stmt = $conn->prepare("
        INSERT INTO products (name, description, price, category, image_url)
        VALUES (:name, :description, :price, :category, :image_url)
    ");
    
    $stmt->execute([
        ':name' => $data['name'],
        ':description' => $data['description'],
        ':price' => $data['price'],
        ':category' => $data['category'],
        ':image_url' => $data['image_url']
    ]);
    
    echo json_encode([
        'success' => true,
        'message' => 'Produit ajouté avec succès',
        'product_id' => $conn->lastInsertId()
    ]);
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
} 