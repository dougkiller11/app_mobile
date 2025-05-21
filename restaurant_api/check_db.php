<?php
header('Content-Type: application/json');
require_once 'config.php';

try {
    // Test 1: Connexion au serveur MySQL
    $conn = new PDO(
        "mysql:host=" . DB_HOST,
        DB_USER,
        DB_PASS
    );
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Test 2: Vérifier si la base de données existe
    $stmt = $conn->query("SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '" . DB_NAME . "'");
    $dbExists = $stmt->fetch();
    
    if (!$dbExists) {
        // Créer la base de données
        $conn->exec("CREATE DATABASE IF NOT EXISTS " . DB_NAME);
        echo json_encode([
            'status' => 'warning',
            'message' => 'Base de données créée avec succès'
        ]);
        exit;
    }
    
    // Test 3: Se connecter à la base de données
    $conn = getConnection();
    
    // Test 4: Vérifier si la table users existe
    $stmt = $conn->query("SHOW TABLES LIKE 'users'");
    $tableExists = $stmt->fetch();
    
    if (!$tableExists) {
        // Créer la table
        $conn->exec("
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                full_name VARCHAR(255) NOT NULL,
                email VARCHAR(255) NOT NULL UNIQUE,
                password VARCHAR(255) NOT NULL,
                token VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ");
        
        $conn->exec("CREATE INDEX IF NOT EXISTS idx_email ON users(email)");
        
        echo json_encode([
            'status' => 'warning',
            'message' => 'Table users créée avec succès'
        ]);
        exit;
    }
    
    // Test 5: Compter les utilisateurs
    $stmt = $conn->query("SELECT COUNT(*) as count FROM users");
    $userCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Base de données opérationnelle',
        'details' => [
            'database_exists' => true,
            'table_exists' => true,
            'user_count' => $userCount
        ]
    ]);
    
} catch (PDOException $e) {
    echo json_encode([
        'status' => 'error',
        'message' => 'Erreur: ' . $e->getMessage()
    ]);
}
?> 