# Guide d'utilisation de l'application Restaurant

Ce guide explique comment tester l'application avec différents types de comptes (admin et client).

## Comptes disponibles

### Compte Administrateur
- **Email**: test@example.com
- **Mot de passe**: admin123

### Compte Client (exemple)
- **Email**: client@example.com
- **Mot de passe**: client123

## Comment lancer l'application

### Option 1: Lancer l'application standard
```bash
flutter run
```
Cette commande lance l'application complète. Vous devrez vous connecter manuellement avec les identifiants ci-dessus.

### Option 2: Lancer l'interface de test avec redirection selon le rôle
```bash
flutter run -t lib/test_admin_page.dart
```
Cette commande lance une interface qui vérifie automatiquement les comptes disponibles et redirige vers:
- L'interface d'administration si connecté en tant qu'admin
- L'interface client si connecté en tant que client
- L'écran de connexion si aucun compte connecté

## Fonctionnalités disponibles

### Interface Admin
- Accès à `admin_product_page.dart` pour gérer toutes les catégories de produits
- Navigation entre les différentes catégories (burgers, pizzas, sushis, etc.)
- Ajout de nouveaux produits avec nom, description, prix et image
- Visualisation et suppression des produits existants

### Interface Client 
- Visualisation des différents menus
- Sélection et commande de produits
- Gestion du panier

## Comportement de l'application

1. **Redirection basée sur le rôle**:
   - Les comptes avec rôle "admin" accèdent directement à la page `admin_product_page.dart`
   - Les comptes avec rôle "client" accèdent à leur page client pour choisir les menus

2. **Boutons de connexion rapide**:
   - Sur l'écran de connexion, des boutons permettent de tester rapidement les deux types de comptes

3. **Déconnexion**:
   - L'icône de déconnexion dans la barre supérieure permet de se déconnecter et revenir à l'écran de connexion

## Remarque importante

Cette version est une interface de test qui simplifie la navigation entre les différentes pages de l'application. Dans la version de production, tous les utilisateurs se connecteront via l'écran de connexion standard et seront redirigés automatiquement vers l'interface correspondant à leur rôle. 