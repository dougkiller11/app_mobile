<?php
require_once 'config.php';

try {
    $conn = getConnection();
    
    // Informations du compte client test
    $email = "client@test.com";
    $password = "client123";
    $fullName = "Client Test";
    $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
    
    // Vérifier si l'utilisateur existe déjà
    $checkStmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
    $checkStmt->execute([$email]);
    
    if ($checkStmt->fetch()) {
        // Mettre à jour le mot de passe si l'utilisateur existe
        $stmt = $conn->prepare("UPDATE users SET password = ?, full_name = ?, role = 'client' WHERE email = ?");
        $stmt->execute([$hashedPassword, $fullName, $email]);
    } else {
        // Créer un nouveau compte client
        $stmt = $conn->prepare("INSERT INTO users (email, password, full_name, role) VALUES (?, ?, ?, 'client')");
        $stmt->execute([$email, $hashedPassword, $fullName]);
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Compte client créé/mis à jour avec succès',
        'credentials' => [
            'email' => $email,
            'password' => $password
        ]
    ]);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
} 