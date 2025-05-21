<?php
require_once 'config.php';

try {
    $conn = getConnection();
    
    // Créer la table products si elle n'existe pas
    $sql = "CREATE TABLE IF NOT EXISTS products (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        price DECIMAL(10,2) NOT NULL,
        category VARCHAR(50) NOT NULL,
        image_url TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";
    
    $conn->exec($sql);
    
    // Ajouter la colonne token à la table users si elle n'existe pas
    $stmt = $conn->query("SHOW COLUMNS FROM users LIKE 'token'");
    if ($stmt->rowCount() == 0) {
        $conn->exec("ALTER TABLE users ADD COLUMN token VARCHAR(255) NULL");
        echo "Colonne token ajoutée à la table users\n";
    }
    
    // Ajouter la colonne last_login à la table users si elle n'existe pas
    $stmt = $conn->query("SHOW COLUMNS FROM users LIKE 'last_login'");
    if ($stmt->rowCount() == 0) {
        $conn->exec("ALTER TABLE users ADD COLUMN last_login TIMESTAMP NULL");
        echo "Colonne last_login ajoutée à la table users\n";
    }
    
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