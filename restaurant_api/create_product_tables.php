<?php
require_once 'config.php';

try {
    // Lecture du fichier SQL
    $sql = file_get_contents('create_product_tables.sql');

    // Exécution des requêtes SQL
    $pdo->exec($sql);
    
    echo "Les tables ont été créées avec succès!\n";
    
    // Vérification de la création des tables
    $tables = ['sushis', 'boissons', 'desserts', 'pizzas', 'entrees', 'burgers'];
    
    echo "\nVérification des tables créées :\n";
    foreach ($tables as $table) {
        $query = $pdo->query("SHOW TABLES LIKE '$table'");
        if ($query->rowCount() > 0) {
            echo "✓ Table '$table' créée avec succès\n";
        } else {
            echo "✗ Erreur : La table '$table' n'a pas été créée\n";
        }
    }

} catch (PDOException $e) {
    die("Erreur lors de la création des tables : " . $e->getMessage());
} 