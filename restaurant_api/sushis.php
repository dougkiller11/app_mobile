<?php
require_once 'config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$conn = getConnection();

switch($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        // Récupérer tous les sushis
        $stmt = $conn->query("SELECT * FROM sushis ORDER BY created_at DESC");
        $sushis = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode(['success' => true, 'data' => $sushis]);
        break;

    case 'POST':
        // Ajouter un sushi
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['name']) || !isset($data['price'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Nom et prix requis']);
            exit();
        }

        $stmt = $conn->prepare("INSERT INTO sushis (name, description, price, image_url) VALUES (?, ?, ?, ?)");
        $result = $stmt->execute([
            $data['name'],
            $data['description'] ?? '',
            $data['price'],
            $data['image_url'] ?? ''
        ]);

        if ($result) {
            echo json_encode([
                'success' => true,
                'message' => 'Sushi ajouté avec succès',
                'id' => $conn->lastInsertId()
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'ajout']);
        }
        break;

    case 'PUT':
        // Modifier un sushi
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'ID requis']);
            exit();
        }

        $fields = [];
        $values = [];
        
        if (isset($data['name'])) {
            $fields[] = 'name = ?';
            $values[] = $data['name'];
        }
        if (isset($data['description'])) {
            $fields[] = 'description = ?';
            $values[] = $data['description'];
        }
        if (isset($data['price'])) {
            $fields[] = 'price = ?';
            $values[] = $data['price'];
        }
        if (isset($data['image_url'])) {
            $fields[] = 'image_url = ?';
            $values[] = $data['image_url'];
        }

        $values[] = $data['id'];
        
        $sql = "UPDATE sushis SET " . implode(', ', $fields) . " WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $result = $stmt->execute($values);

        if ($result) {
            echo json_encode(['success' => true, 'message' => 'Sushi modifié avec succès']);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la modification']);
        }
        break;

    case 'DELETE':
        // Supprimer un sushi
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!isset($data['id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'ID requis']);
            exit();
        }

        $stmt = $conn->prepare("DELETE FROM sushis WHERE id = ?");
        $result = $stmt->execute([$data['id']]);

        if ($result) {
            echo json_encode(['success' => true, 'message' => 'Sushi supprimé avec succès']);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la suppression']);
        }
        break;
} 