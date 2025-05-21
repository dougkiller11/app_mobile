@echo off
echo Installation de l'API Restaurant...

REM Créer le dossier restaurant_api dans htdocs
mkdir "C:\xampp\htdocs\restaurant_api"

REM Copier les fichiers PHP
copy "restaurant_api\*.php" "C:\xampp\htdocs\restaurant_api\"
copy "restaurant_api\*.sql" "C:\xampp\htdocs\restaurant_api\"

echo Installation terminée !
echo.
echo N'oubliez pas de :
echo 1. Démarrer XAMPP (Apache et MySQL)
echo 2. Importer la base de données via phpMyAdmin
echo.
pause 