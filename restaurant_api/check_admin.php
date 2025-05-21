<?php
require_once 'config.php';

function isAdmin() {
    // Vérifier si le token est présent dans les headers
    $headers = getallheaders();
    $token = isset($headers['Authorization']) ? str_replace('Bearer ', '', $headers['Authorization']) : null;
    
    if (!$token) {
        return false;
    }
    
    try {
        $conn = getConnection();
        
        // Vérifier si le token existe et correspond à un admin
        $stmt = $conn->prepare("SELECT role FROM users WHERE token = ?");
        $stmt->execute([$token]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        return $user && $user['role'] === 'admin';
    } catch (PDOException $e) {
        error_log("Erreur lors de la vérification du rôle admin: " . $e->getMessage());
        return false;
    }
}

try {
    $conn = getConnection();
    
    // Récupérer tous les utilisateurs avec leurs rôles
    $stmt = $conn->query("SELECT id, email, full_name, role FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'users' => $users
    ]);
} catch (PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
} 