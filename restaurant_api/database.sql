-- Création de la base de données
CREATE DATABASE IF NOT EXISTS restaurant_db;
USE restaurant_db;

-- Création de la table utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    token VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Ajout de l'index sur l'email pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_email ON users(email); 