<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Vérifier le chemin du fichier
$file_path = __FILE__;
$dir_path = __DIR__;

// Vérifier les permissions
$file_exists = file_exists($file_path);
$file_readable = is_readable($file_path);
$dir_exists = file_exists($dir_path);
$dir_readable = is_readable($dir_path);

// Vérifier le document root
$doc_root = $_SERVER['DOCUMENT_ROOT'];

// Afficher les informations
echo "Test Root PHP\n";
echo "File path: $file_path\n";
echo "Directory path: $dir_path\n";
echo "Document root: $doc_root\n";
echo "File exists: " . ($file_exists ? 'Yes' : 'No') . "\n";
echo "File readable: " . ($file_readable ? 'Yes' : 'No') . "\n";
echo "Directory exists: " . ($dir_exists ? 'Yes' : 'No') . "\n";
echo "Directory readable: " . ($dir_readable ? 'Yes' : 'No') . "\n";
?> 