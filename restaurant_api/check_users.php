<?php
header('Content-Type: application/json');
require_once 'config.php';

try {
    $conn = getConnection();
    
    // Vérifier si la table users existe
    $stmt = $conn->query("SHOW TABLES LIKE 'users'");
    if ($stmt->rowCount() == 0) {
        // Créer la table users si elle n'existe pas
        $sql = "CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(255) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL,
            full_name VARCHAR(255) NOT NULL,
            role ENUM('admin', 'client') NOT NULL DEFAULT 'client',
            token VARCHAR(255) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP NULL
        )";
        $conn->exec($sql);
        echo json_encode(['message' => 'Table users créée avec succès']);
    } else {
        // Afficher la structure de la table
        $stmt = $conn->query("DESCRIBE users");
        $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode([
            'message' => 'Table users existe',
            'structure' => $columns
        ]);
    }
} catch (PDOException $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
?> 