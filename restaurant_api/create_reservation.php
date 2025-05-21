<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
file_put_contents('debug_create_reservation.log', "Script hit at: " . date('Y-m-d H:i:s') . "\n", FILE_APPEND);
$raw_input = file_get_contents("php://input");
file_put_contents('debug_create_reservation.log', "Raw input: " . $raw_input . "\n", FILE_APPEND);
// Attempt to decode, but don't exit if it fails here, just log it
$test_data = json_decode($raw_input);
if (json_last_error() !== JSON_ERROR_NONE) {
    file_put_contents('debug_create_reservation.log', "JSON decode error: " . json_last_error_msg() . "\n", FILE_APPEND);
} else {
    file_put_contents('debug_create_reservation.log', "JSON decoded successfully.\n", FILE_APPEND);
}

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- Connexion à la base de données ---
// Remplacez par vos informations de connexion réelles
$servername = "localhost";
$username = "VOTRE_VRAI_NOM_UTILISATEUR_MYSQL";
$password = "VOTRE_VRAI_MOT_DE_PASSE_MYSQL";
$dbname = "VOTRE_VRAI_NOM_DE_BASE_DE_DONNEES";

// Créer la connexion
$conn = new mysqli($servername, $username, $password, $dbname);

// Vérifier la connexion
if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "Échec de la connexion à la base de données: " . $conn->connect_error]);
    exit();
}

// --- Récupérer les données de la requête ---
$data = json_decode(file_get_contents("php://input"));

// --- Validation des données (basique) ---
if (
    !isset($data->name) || empty(trim($data->name)) ||
    !isset($data->phone) || empty(trim($data->phone)) ||
    !isset($data->date) || empty(trim($data->date)) ||
    !isset($data->time) || empty(trim($data->time)) ||
    !isset($data->numberOfPeople) || !is_numeric($data->numberOfPeople) || $data->numberOfPeople <= 0
) {
    http_response_code(400);
    echo json_encode(["status" => "error", "message" => "Données de réservation incomplètes ou invalides."]);
    exit();
}

// --- Validation de l'heure minimale (11:30) ---
$reservation_time_parts = explode(':', $data->time);
if (count($reservation_time_parts) == 2) {
    $hour = intval($reservation_time_parts[0]);
    $minute = intval($reservation_time_parts[1]);

    if ($hour < 11 || ($hour == 11 && $minute < 30)) {
        http_response_code(400); // Bad Request
        echo json_encode(["status" => "error", "message" => "Les réservations ne sont possibles qu'à partir de 11h30."]);
        exit();
    }
} else {
    http_response_code(400); // Bad Request
    echo json_encode(["status" => "error", "message" => "Format de l'heure invalide. Utilisez HH:MM."]);
    exit();
}

// --- Préparer les données pour l'insertion ---
$name = $conn->real_escape_string(trim($data->name));
$phone = $conn->real_escape_string(trim($data->phone));
$reservation_date = $conn->real_escape_string(trim($data->date)); // Format YYYY-MM-DD attendu
$reservation_time = $conn->real_escape_string(trim($data->time)); // Format HH:MM attendu
$number_of_people = intval($data->numberOfPeople);
$special_requests = isset($data->specialRequests) ? $conn->real_escape_string(trim($data->specialRequests)) : null;
$user_id = isset($data->userId) ? $conn->real_escape_string(trim($data->userId)) : null; // Peut être l'email
$status = 'pending'; // Statut par défaut

// --- Insérer la réservation dans la base de données ---
$sql = "INSERT INTO reservations (user_id, name, phone, reservation_date, reservation_time, number_of_people, special_requests, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)";

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    echo json_encode(["status" => "error", "message" => "Erreur de préparation de la requête: " . $conn->error]);
    exit();
}

// Le type 's' est pour string, 'i' pour integer, 'd' pour double, 'b' pour blob
// Ajustez les types si nécessaire, par ex. si user_id est un int.
$stmt->bind_param("ssssisss", 
    $user_id, 
    $name, 
    $phone, 
    $reservation_date, 
    $reservation_time, 
    $number_of_people, 
    $special_requests, 
    $status
);

if ($stmt->execute()) {
    echo json_encode(["status" => "success", "message" => "Réservation créée avec succès.", "reservation_id" => $stmt->insert_id]);
} else {
    echo json_encode(["status" => "error", "message" => "Erreur lors de la création de la réservation: " . $stmt->error]);
}

$stmt->close();
$conn->close();

?> 