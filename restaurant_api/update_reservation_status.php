<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST"); // Can also be PUT
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// --- Connexion à la base de données ---
// Remplacez par vos informations de connexion réelles
$servername = "localhost";
$username = "votre_utilisateur_bdd"; // VOTRE NOM D'UTILISATEUR DE BASE DE DONNÉES
$password = "votre_mot_de_passe_bdd"; // VOTRE MOT DE PASSE DE BASE DE DONNÉES
$dbname = "votre_base_de_donnees";   // LE NOM DE VOTRE BASE DE DONNÉES

echo json_encode(["status" => "success", "message" => "Test create_reservation.php OK"]);
exit();
?> 