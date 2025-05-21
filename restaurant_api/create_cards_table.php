<?php
require_once 'db_connect.php';

try {
    // Créer la table cards
    $sql = "CREATE TABLE IF NOT EXISTS cards (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        card_number VARCHAR(255) NOT NULL,
        card_holder VARCHAR(255) NOT NULL,
        expiry_date VARCHAR(10) NOT NULL,
        cvv VARCHAR(4) NOT NULL,
        is_default BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )";

    $pdo->exec($sql);
    echo "Table 'cards' créée avec succès\n";
} catch (PDOException $e) {
    echo "Erreur lors de la création de la table: " . $e->getMessage() . "\n";
}
?> 