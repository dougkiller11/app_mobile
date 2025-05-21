<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Connexion à la base de données
$host = 'localhost';
$dbname = 'restaurant_db';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "Connexion à la base de données réussie\n\n";

    // Vérifier si la base de données existe
    $stmt = $pdo->query("SELECT DATABASE()");
    $currentDb = $stmt->fetchColumn();
    echo "Base de données actuelle : $currentDb\n\n";

    // Vérifier si la table users existe
    $stmt = $pdo->query("SHOW TABLES LIKE 'users'");
    if ($stmt->rowCount() == 0) {
        echo "La table users n'existe pas. Création en cours...\n";
        $pdo->exec("CREATE TABLE users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(255) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL,
            role ENUM('admin', 'client') NOT NULL DEFAULT 'client',
            token VARCHAR(255),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )");
        echo "Table users créée avec succès\n\n";
    } else {
        echo "La table users existe déjà\n\n";
    }

    // Vérifier la structure de la table users
    echo "Structure de la table users :\n";
    $stmt = $pdo->query("DESCRIBE users");
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        print_r($row);
    }
    echo "\n";

    // Vérifier si l'admin existe
    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute(['adminlocal@example.com']);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$admin) {
        echo "L'utilisateur admin n'existe pas. Création en cours...\n";
        $hashedPassword = password_hash('admin123', PASSWORD_DEFAULT);
        $stmt = $pdo->prepare("INSERT INTO users (email, password, role) VALUES (?, ?, 'admin')");
        $stmt->execute(['adminlocal@example.com', $hashedPassword]);
        echo "Utilisateur admin créé avec succès\n\n";
    } else {
        echo "L'utilisateur admin existe déjà :\n";
        print_r($admin);
        echo "\n";
    }

    // Afficher tous les utilisateurs
    echo "Liste de tous les utilisateurs :\n";
    $stmt = $pdo->query("SELECT id, email, role, token FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    print_r($users);
    echo "\n";

    // Vérifier les tokens
    echo "Vérification des tokens :\n";
    $stmt = $pdo->query("SELECT email, token FROM users WHERE token IS NOT NULL");
    $tokens = $stmt->fetchAll(PDO::FETCH_ASSOC);
    print_r($tokens);
    echo "\n";

} catch(PDOException $e) {
    echo "Erreur : " . $e->getMessage() . "\n";
}
?> 