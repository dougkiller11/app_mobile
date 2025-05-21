<?php
// Configuration de la base de données
define('DB_HOST', 'localhost');
define('DB_USER', 'root');
define('DB_PASS', '');
define('DB_NAME', 'restaurant_db');

// Fonction de log
function writeLog($message) {
    $timestamp = date('Y-m-d H:i:s');
    error_log("[$timestamp] $message");
}

// Connexion à la base de données
function getConnection() {
    $host = 'localhost';
    $dbname = 'restaurant_db';
    $username = 'root';
    $password = '';

    try {
        $conn = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        return $conn;
    } catch(PDOException $e) {
        writeLog("Erreur de connexion : " . $e->getMessage());
        throw $e;
    }
}

// Créer la base de données et les tables si elles n'existent pas
function initDatabase() {
    try {
        // Connexion sans sélectionner de base de données
        $conn = new PDO("mysql:host=" . DB_HOST, DB_USER, DB_PASS);
        $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        // Créer la base de données si elle n'existe pas
        $conn->exec("CREATE DATABASE IF NOT EXISTS " . DB_NAME);
        writeLog("Base de données créée ou déjà existante");
        
        // Sélectionner la base de données
        $conn->exec("USE " . DB_NAME);
        
        // Créer la table users si elle n'existe pas
        $conn->exec("
            CREATE TABLE IF NOT EXISTS users (
                id INT AUTO_INCREMENT PRIMARY KEY,
                full_name VARCHAR(255) NOT NULL,
                email VARCHAR(255) NOT NULL UNIQUE,
                password VARCHAR(255) NOT NULL,
                role ENUM('admin', 'client') DEFAULT 'client',
                token VARCHAR(255),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_login TIMESTAMP NULL,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
            )
        ");
        writeLog("Table users créée ou déjà existante");
        
        // Vérifier et ajouter les colonnes manquantes
        $columns = $conn->query("SHOW COLUMNS FROM users")->fetchAll(PDO::FETCH_COLUMN);
        
        if (!in_array('role', $columns)) {
            $conn->exec("ALTER TABLE users ADD COLUMN role ENUM('admin', 'client') DEFAULT 'client'");
            writeLog("Colonne role ajoutée");
        }
        
        if (!in_array('last_login', $columns)) {
            $conn->exec("ALTER TABLE users ADD COLUMN last_login TIMESTAMP NULL");
            writeLog("Colonne last_login ajoutée");
        }
        
        return true;
    } catch(PDOException $e) {
        writeLog("ERREUR d'initialisation de la base de données: " . $e->getMessage());
        throw $e;
    }
}

// Initialiser la base de données au chargement du fichier
try {
    initDatabase();
} catch (Exception $e) {
    writeLog("Erreur lors de l'initialisation de la base de données: " . $e->getMessage());
}
?> 