<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Vérifier la version de PHP
echo "PHP Version: " . PHP_VERSION . "\n";

// Vérifier les modules chargés
echo "Loaded modules:\n";
print_r(get_loaded_extensions());

// Vérifier les variables d'environnement
echo "\nServer variables:\n";
print_r($_SERVER);

// Vérifier les permissions
echo "\nFile permissions:\n";
echo "Current file: " . __FILE__ . "\n";
echo "File exists: " . (file_exists(__FILE__) ? 'Yes' : 'No') . "\n";
echo "File readable: " . (is_readable(__FILE__) ? 'Yes' : 'No') . "\n";
echo "File permissions: " . fileperms(__FILE__) . "\n";

// Vérifier le dossier
echo "\nDirectory info:\n";
echo "Current directory: " . __DIR__ . "\n";
echo "Directory exists: " . (file_exists(__DIR__) ? 'Yes' : 'No') . "\n";
echo "Directory readable: " . (is_readable(__DIR__) ? 'Yes' : 'No') . "\n";
echo "Directory permissions: " . fileperms(__DIR__) . "\n";

// Afficher le message de test
echo "\nHello World!";
?> 