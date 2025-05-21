<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Fonction pour vérifier un chemin
function checkPath($path) {
    $result = [
        'path' => $path,
        'exists' => file_exists($path),
        'is_dir' => is_dir($path),
        'is_file' => is_file($path),
        'readable' => is_readable($path),
        'writable' => is_writable($path),
        'permissions' => fileperms($path),
    ];
    
    if ($result['is_dir']) {
        $result['contents'] = scandir($path);
    }
    
    return $result;
}

// Chemins à vérifier
$paths = [
    'current_dir' => __DIR__,
    'document_root' => $_SERVER['DOCUMENT_ROOT'],
    'htdocs' => $_SERVER['DOCUMENT_ROOT'],
    'restaurant_api' => $_SERVER['DOCUMENT_ROOT'] . '/restaurant_api',
    'parent_dir' => dirname(__DIR__),
];

// Vérifier chaque chemin
$results = [];
foreach ($paths as $name => $path) {
    $results[$name] = checkPath($path);
}

// Afficher les résultats
header('Content-Type: application/json');
echo json_encode($results, JSON_PRETTY_PRINT);
?> 