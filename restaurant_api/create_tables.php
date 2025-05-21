<?php
require_once 'config.php';

try {
    $conn = getConnection();
    
    // Création de la table burgers
    $conn->exec("CREATE TABLE IF NOT EXISTS burgers (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        description TEXT,
        price DECIMAL(10,2) NOT NULL,
        image_url VARCHAR(255),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )");

    echo "Tables créées avec succès";
} catch(PDOException $e) {
    echo "Erreur lors de la création des tables: " . $e->getMessage();
}
?> 