<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Vérifier la configuration PHP
$php_info = [
    'version' => PHP_VERSION,
    'display_errors' => ini_get('display_errors'),
    'error_reporting' => ini_get('error_reporting'),
    'max_execution_time' => ini_get('max_execution_time'),
    'memory_limit' => ini_get('memory_limit'),
    'post_max_size' => ini_get('post_max_size'),
    'upload_max_filesize' => ini_get('upload_max_filesize'),
];

// Vérifier les variables d'environnement
$server_info = [
    'SERVER_SOFTWARE' => $_SERVER['SERVER_SOFTWARE'] ?? 'Non disponible',
    'SERVER_NAME' => $_SERVER['SERVER_NAME'] ?? 'Non disponible',
    'SERVER_ADDR' => $_SERVER['SERVER_ADDR'] ?? 'Non disponible',
    'SERVER_PORT' => $_SERVER['SERVER_PORT'] ?? 'Non disponible',
    'DOCUMENT_ROOT' => $_SERVER['DOCUMENT_ROOT'] ?? 'Non disponible',
    'SCRIPT_FILENAME' => $_SERVER['SCRIPT_FILENAME'] ?? 'Non disponible',
    'REQUEST_URI' => $_SERVER['REQUEST_URI'] ?? 'Non disponible',
    'REQUEST_METHOD' => $_SERVER['REQUEST_METHOD'] ?? 'Non disponible',
    'HTTP_HOST' => $_SERVER['HTTP_HOST'] ?? 'Non disponible',
    'REMOTE_ADDR' => $_SERVER['REMOTE_ADDR'] ?? 'Non disponible',
];

// Vérifier les modules PHP chargés
$loaded_modules = get_loaded_extensions();

// Vérifier les permissions du répertoire
$dir_path = __DIR__;
$dir_exists = file_exists($dir_path);
$dir_readable = is_readable($dir_path);
$dir_writable = is_writable($dir_path);
$dir_permissions = fileperms($dir_path);

// Retourner les informations
echo json_encode([
    'success' => true,
    'message' => 'Index accessible',
    'php_info' => $php_info,
    'server_info' => $server_info,
    'loaded_modules' => $loaded_modules,
    'directory_info' => [
        'path' => $dir_path,
        'exists' => $dir_exists,
        'readable' => $dir_readable,
        'writable' => $dir_writable,
        'permissions' => $dir_permissions,
    ],
], JSON_PRETTY_PRINT);
?> 