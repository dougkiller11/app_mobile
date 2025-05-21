<?php
require_once 'config.php';

try {
    $conn = getConnection();
    
    // Ajouter la colonne token si elle n'existe pas
    $conn->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS token VARCHAR(255)");
    
    echo json_encode([
        'success' => true,
        'message' => 'Base de données mise à jour avec succès'
    ]);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?> 