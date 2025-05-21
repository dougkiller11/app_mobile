<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST"); // Changed to POST to receive user_id in body, or use GET with query param
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- Placeholder pour la vérification de l'utilisateur authentifié (CRUCIAL) ---
// Vous DEVEZ implémenter une vérification de l'utilisateur. 
// Par exemple, vérifier un token JWT passé dans l'en-tête Authorization 
// et s'assurer que le user_id demandé correspond à celui du token.
/*
require_once 'auth_check.php'; // Votre script de vérification de token
$decoded_token = Authentification::verifierToken();
if (!$decoded_token) {
    http_response_code(401);
    echo json_encode(["status" => "error", "message" => "Accès non autorisé. Token invalide ou manquant."]);
    exit();
}
$token_user_id = $decoded_token->data->user_email; // Supposons que l'email est dans le token comme user_id
*/

// --- Connexion à la base de données ---
$servername = "localhost"; 
$username = "votre_utilisateur_bdd"; 
$password = "votre_mot_de_passe_bdd";
$dbname = "votre_base_de_donnees";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "DB Connection Failed: " . $conn->connect_error]);
    exit();
}

// --- Récupérer les données de la requête ---
$data = json_decode(file_get_contents("php://input"));

// --- Validation de user_id (doit correspondre à l'utilisateur authentifié) ---
if (!isset($data->user_id) || empty(trim($data->user_id))) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "user_id manquant."]);
    exit();
}
$user_id_from_request = trim($data->user_id);

// EN PRODUCTION: Assurez-vous que $user_id_from_request correspond à l'utilisateur authentifié via token
// if ($user_id_from_request !== $token_user_id) {
//     http_response_code(403); // Forbidden
//     echo json_encode(["status" => "error", "message" => "Accès non autorisé aux réservations de cet utilisateur."]);
//     exit();
// }

$current_user_id = $conn->real_escape_string($user_id_from_request);

// --- Récupérer les réservations de l'utilisateur ---
$reservations = [];
// Trier par date de réservation la plus récente en premier, puis par heure
$sql = "SELECT id, user_id, name, phone, reservation_date, reservation_time, number_of_people, special_requests, status, created_at 
        FROM reservations 
        WHERE user_id = ? 
        ORDER BY reservation_date DESC, reservation_time ASC";

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Erreur de préparation de la requête: " . $conn->error]);
    exit();
}

$stmt->bind_param("s", $current_user_id);

if ($stmt->execute()) {
    $result = $stmt->get_result();
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            $row['numberOfPeople'] = intval($row['number_of_people']); 
            $reservations[] = $row;
        }
        echo json_encode(["status" => "success", "data" => $reservations]);
    } else {
        echo json_encode(["status" => "success", "data" => [], "message" => "Aucune réservation trouvée pour cet utilisateur."]);
    }
} else {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Erreur lors de la récupération des réservations: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?> 