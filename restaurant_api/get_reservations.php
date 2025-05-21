<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);
file_put_contents('debug_get_reservations.log', "Script get_reservations.php hit at: " . date('Y-m-d H:i:s') . "\n", FILE_APPEND);

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET"); // Admins will GET the list
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- Placeholder pour la vérification de l'administrateur ---
// Vous DEVEZ implémenter une vérification d'administrateur sécurisée ici.
// Par exemple, vérifier un token JWT d'administrateur passé dans l'en-tête Authorization.
/*
$headers = getallheaders();
$authHeader = $headers['Authorization'] ?? null;
if ($authHeader) {
    list($type, $token) = explode(" ", $authHeader, 2);
    if (strcasecmp($type, "Bearer") == 0) {
        // Valider le token (ex: avec une librairie JWT et votre clé secrète)
        // Si le token est invalide ou n'est pas un admin, renvoyez une erreur 401 ou 403.
        // $isAdmin = validateAdminToken($token); 
        // if (!$isAdmin) { ... exit ... }
    } else {
        http_response_code(401); // Unauthorized
        echo json_encode(["status" => "error", "message" => "Type d'autorisation invalide."]);
        exit();
    }
} else {
    http_response_code(401); // Unauthorized
    echo json_encode(["status" => "error", "message" => "Token d'autorisation manquant."]);
    exit();
}
*/
// Pour cet exemple, nous allons sauter la vérification d'admin, mais C'EST CRUCIAL EN PRODUCTION.

// --- Connexion à la base de données ---
$servername = "localhost";
$username = "votre_utilisateur_bdd";
$password = "votre_mot_de_passe_bdd";
$dbname = "votre_base_de_donnees";

$conn = new mysqli($servername, $username, $password, $dbname);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "DB Connection Failed: " . $conn->connect_error]);
    file_put_contents('debug_get_reservations.log', "Error connecting to DB: " . $conn->connect_error . "\n", FILE_APPEND);
    exit();
}

// --- Récupérer les réservations ---
$reservations = [];
// Trier par date de réservation la plus récente en premier, puis par heure
$sql = "SELECT id, user_id, name, phone, reservation_date, reservation_time, number_of_people, special_requests, status, created_at 
        FROM reservations 
        ORDER BY reservation_date DESC, reservation_time ASC";

$result = $conn->query($sql);

if ($result) {
    if ($result->num_rows > 0) {
        while($row = $result->fetch_assoc()) {
            // Convertir le nombre de personnes en int si ce n'est pas déjà le cas (au cas où la BDD le stocke différemment)
            $row['numberOfPeople'] = intval($row['number_of_people']); 
            $reservations[] = $row;
        }
        echo json_encode(["status" => "success", "data" => $reservations]);
    } else {
        echo json_encode(["status" => "success", "data" => [], "message" => "Aucune réservation trouvée."]);
    }
} else {
    http_response_code(500);
    echo json_encode(["status" => "error", "message" => "Erreur lors de la récupération des réservations: " . $conn->error]);
    file_put_contents('debug_get_reservations.log', "Error fetching reservations: " . $conn->error . "\n", FILE_APPEND);
}

file_put_contents('debug_get_reservations.log', "Script get_reservations.php finished. Result: " . ($result ? "OK, rows: " . $result->num_rows : 'Query failed or no result object') . "\n", FILE_APPEND);
$conn->close();
?> 