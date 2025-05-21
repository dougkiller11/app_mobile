<?php
require_once 'config.php';

try {
    $conn = getConnection();
    
    // Nouveau mot de passe pour l'admin
    $newPassword = "admin123"; // Mot de passe par défaut
    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
    
    // Mettre à jour le mot de passe de l'admin
    $stmt = $conn->prepare("UPDATE users SET password = ? WHERE email = ? AND role = 'admin'");
    $result = $stmt->execute([$hashedPassword, 'test@example.com']);
    
    if ($result) {
        echo json_encode([
            'success' => true,
            'message' => 'Mot de passe admin réinitialisé avec succès',
            'credentials' => [
                'email' => 'test@example.com',
                'password' => $newPassword
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Aucun compte admin trouvé'
        ]);
    }
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
} 