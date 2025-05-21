<?php
// Activer l'affichage des erreurs pour le débogage
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'config.php';

writeLog('Début de la requête');
writeLog('Méthode: ' . $_SERVER['REQUEST_METHOD']);

// En-têtes CORS - Doivent être définis avant toute sortie
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=UTF-8');

// Gérer les requêtes OPTIONS (pre-flight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    writeLog('Requête OPTIONS reçue - Réponse préliminaire CORS');
    http_response_code(200);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Récupérer les données POST brutes
    $input = file_get_contents('php://input');
    writeLog('Données reçues: ' . $input);
    
    $postData = json_decode($input, true);

    // Si les données ne sont pas en JSON, essayer les données POST normales
    if (json_last_error() !== JSON_ERROR_NONE) {
        writeLog('Erreur JSON: ' . json_last_error_msg());
        writeLog('Tentative de lecture des données POST normales');
        $postData = $_POST;
        writeLog('Données POST: ' . print_r($postData, true));
    }

    // Récupérer les données
    $email = $postData['email'] ?? '';
    $password = $postData['password'] ?? '';
    $fullName = $postData['full_name'] ?? '';

    writeLog("Email: $email");
    writeLog("Nom complet: $fullName");

    // Validation des données
    if (empty($email) || empty($password) || empty($fullName)) {
        writeLog('Erreur: Champs manquants');
        echo json_encode([
            'success' => false, 
            'message' => 'Tous les champs sont requis (email, mot de passe et nom complet)'
        ]);
        exit;
    }

    // Valider le format de l'email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        writeLog('Erreur: Format email invalide');
        echo json_encode([
            'success' => false, 
            'message' => 'Format d\'email invalide'
        ]);
        exit;
    }

    try {
        $conn = getConnection();
        writeLog('Connexion à la base de données réussie');
        
        // Vérifier si l'email existe déjà
        $stmt = $conn->prepare('SELECT id FROM users WHERE email = ?');
        $stmt->execute([$email]);
        if ($stmt->fetch()) {
            writeLog('Erreur: Email déjà utilisé');
            echo json_encode([
                'success' => false, 
                'message' => 'Cet email est déjà utilisé'
            ]);
            exit;
        }

        // Hasher le mot de passe
        $hashedPassword = password_hash($password, PASSWORD_DEFAULT);
        
        // Insérer le nouvel utilisateur avec le nom complet
        $stmt = $conn->prepare('INSERT INTO users (email, password, full_name, created_at) VALUES (?, ?, ?, NOW())');
        $stmt->execute([$email, $hashedPassword, $fullName]);

        writeLog('Inscription réussie');
        echo json_encode([
            'success' => true, 
            'message' => 'Inscription réussie'
        ]);
    } catch (PDOException $e) {
        writeLog('Erreur SQL: ' . $e->getMessage());
        error_log("Erreur SQL: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Erreur lors de l\'inscription: ' . $e->getMessage()
        ]);
    }
} else {
    writeLog('Méthode non autorisée: ' . $_SERVER['REQUEST_METHOD']);
    echo json_encode([
        'success' => false,
        'message' => 'Méthode non autorisée. Utilisez POST pour l\'inscription.'
    ]);
}
?> 