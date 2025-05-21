<?php
// Activer l'affichage des erreurs
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Vérifier la version de PHP
echo "PHP Version: " . phpversion() . "\n";

// Vérifier les modules chargés
echo "Loaded Modules:\n";
print_r(get_loaded_extensions());

// Vérifier le chemin du fichier
echo "\nCurrent file path: " . __FILE__ . "\n";
echo "Document root: " . $_SERVER['DOCUMENT_ROOT'] . "\n";

// Test simple
echo "\nTest message: Hello World!";

echo "Test PHP - Si vous voyez ce message, PHP fonctionne correctement!";
phpinfo();
?> 