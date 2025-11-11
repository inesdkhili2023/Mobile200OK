# 📱 Feedback App - Module Historique & Feedback

## 📋 Description du projet
Application Flutter mobile pour la gestion des feedbacks des prestations de services avec modération locale, SQLite et statistiques.

---

## 🏗️ Architecture du projet

```
lib/
├── main.dart                          # Point d'entrée (24 lignes)
├── core/                              # Configuration globale (future)
└── features/
    └── feedback/
        ├── data/
        │   └── feedback_db.dart       # 🔵 SQLite - CRUD + Statistiques
        ├── models/
        │   └── feedback_model.dart    # 🔵 Modèle de données avec Equatable
        ├── services/
        │   └── moderation_service.dart # 🔵 Modération locale (mots interdits)
        ├── screens/
        │   ├── feedback_home_screen.dart        # Écran principal + formulaire
        │   ├── feedback_summary_screen.dart     # Liste + statistiques
        │   ├── feedback_edit_screen.dart        # Édition d'un feedback
        │   ├── feedback_submitted_screen.dart   # Confirmation ajout
        │   └── feedback_updated_screen.dart     # Confirmation modification
        └── widgets/
            └── bottom_navigation.dart   # Navigation réutilisable

assets/
└── bad_words.txt                      # 🔵 Liste des mots interdits
```

---

## ✨ Fonctionnalités implémentées

### 1️⃣ **Gestion des feedbacks (CRUD complet)**
- ✅ Création de feedback avec note (1-5 étoiles) et commentaire
- ✅ Lecture de tous les feedbacks (triés par date DESC)
- ✅ Modification d'un feedback existant
- ✅ Suppression d'un feedback

### 2️⃣ **Modération locale automatique** 🚫
- ✅ Détection des mots interdits depuis `assets/bad_words.txt`
- ✅ Vérification à la **création** ET à la **modification**
- ✅ Alerte bloquante : "This message contains an insult. Please try again."
- ✅ Pattern Singleton pour performances optimales

### 3️⃣ **Base de données SQLite** 💾
- ✅ Persistance locale (données conservées après fermeture)
- ✅ Requêtes SQL avancées (AVG, COUNT, GROUP BY)
- ✅ Calcul automatique de la moyenne des notes
- ✅ Statistiques par statut (In Progress / Finished)
- ✅ Moyenne par service

### 4️⃣ **Interface utilisateur** 🎨
- ✅ Tableau de bord avec prestations (statuts simulés)
- ✅ Timeline avec dates (timestamp `created_at`)
- ✅ Notes étoilées interactives
- ✅ Écrans de confirmation (Submitted / Updated)
- ✅ Navigation fluide avec animations

---

## 🗄️ Structure de la base de données

### Table `feedbacks`
```sql
CREATE TABLE feedbacks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  service TEXT NOT NULL,              -- Nom du service (Electrician, Plumber, etc.)
  status TEXT NOT NULL,               -- In Progress / Finished
  rating INTEGER NOT NULL,            -- Note de 1 à 5
  comment TEXT NOT NULL,              -- Commentaire de l'utilisateur
  price_label TEXT NOT NULL,          -- Label du prix (89DT, 109DT, etc.)
  created_at INTEGER NOT NULL         -- Timestamp de création
)
```

---

## 🔧 Technologies utilisées

| Technologie | Version | Usage |
|------------|---------|-------|
| **Flutter** | ^3.5.0 | Framework mobile |
| **Dart** | ^3.5.0 | Langage de programmation |
| **sqflite** | ^2.3.3 | Base de données SQLite |
| **path** | ^1.9.0 | Gestion des chemins de fichiers |
| **shared_preferences** | ^2.2.3 | Persistance clé-valeur (futur) |
| **equatable** | - | Comparaison d'objets |
| **fl_chart** | ^0.66.0 | Graphiques (futur) |
| **timeline_tile** | ^2.0.0 | Timeline UI (futur) |

---

## 🚀 Installation et lancement

### Prérequis
- Flutter SDK 3.5.0+
- Android Studio / Xcode
- Émulateur Android ou iOS

### Étapes
```bash
# 1. Cloner le projet
git clone <votre-repo>
cd feedback_app

# 2. Installer les dépendances
flutter pub get

# 3. Vérifier les périphériques
flutter devices

# 4. Lancer sur émulateur
flutter run -d emulator-5554

# OU sur appareil physique
flutter run
```

---

## 📂 Points d'intégration pour vos collègues

### 🔗 **Module 1 : Authentification**
**Fichier à modifier :** `lib/main.dart`
```dart
// Remplacer FeedbackHomeScreen par votre AuthScreen
home: const AuthScreen(),
```

### 🔗 **Module 2 : Gestion des services**
**Dossier à créer :** `lib/features/services/`
```dart
// Dans feedback_home_screen.dart, remplacer la liste mockée par :
final services = await ServiceDb.instance.getAll();
```

### 🔗 **Module 3 : Profil utilisateur**
**Utiliser SharedPreferences :**
```dart
import 'package:shared_preferences/shared_preferences.dart';

final prefs = await SharedPreferences.getInstance();
String? userName = prefs.getString('user_name');
```

### 🔗 **Module 4 : Notifications push**
**Ajouter après l'insertion :**
```dart
await FeedbackDb.instance.insert(model);
// Appeler votre service de notification ici
await NotificationService.instance.send('Merci pour votre avis');
```

---

## 📝 Modération locale - Comment ça marche ?

### Flux de vérification
```
1. Utilisateur tape un commentaire
2. Clique sur "Submit" ou "Update"
3. ⚠️ VÉRIFICATION MODÉRATION
   ├─ Si mot interdit détecté → Alerte affichée ❌
   └─ Si texte propre → Enregistrement dans SQLite ✅
4. Navigation vers écran de confirmation
```

### Ajouter des mots interdits
**Fichier :** `assets/bad_words.txt`
```
idiot
stupide
nul
votre_nouveau_mot
```
Un mot par ligne, l'app recharge automatiquement au redémarrage.

---

## 🧪 Tests manuels

### Test 1 : Ajout de feedback normal
1. Sélectionner un service (Electrician)
2. Ajouter une note (4 étoiles)
3. Commenter : "Great service!"
4. Cliquer "Submit"
5. ✅ Confirmation affichée

### Test 2 : Modération à la création
1. Sélectionner un service
2. Ajouter une note
3. Commenter : "This is stupid"
4. Cliquer "Submit"
5. ⚠️ Alerte "Inappropriate Content"

### Test 3 : Modération à la modification
1. Aller dans "View Summary"
2. Cliquer "Update" sur un feedback
3. Modifier le texte : "This is terrible"
4. Cliquer "Update"
5. ⚠️ Alerte "Inappropriate Content"

### Test 4 : Statistiques
1. Créer plusieurs feedbacks
2. Aller dans "View Summary"
3. Vérifier :
   - Moyenne globale affichée
   - Comptage In Progress / Finished
   - Liste des feedbacks

---

## 🎯 Checklist pour l'intégration

- [ ] Fusionner avec module d'authentification
- [ ] Remplacer les services mockés par vraie API
- [ ] Ajouter les notifications push réelles
- [ ] Implémenter SharedPreferences pour préférences utilisateur
- [ ] Ajouter graphiques avec fl_chart
- [ ] Ajouter timeline visuelle avec timeline_tile
- [ ] Tests unitaires et tests d'intégration
- [ ] Documentation API complète

---

## 👥 Auteurs & Contact

**Module 6 : Historique & Feedback**
- Développé par : [Votre nom]
- Date : Novembre 2025
- Framework : Flutter 3.5.0

**Pour les questions d'intégration :**
- 📧 Email : [votre-email]
- 💬 Discord/Teams : [votre-pseudo]

---

## 📄 Licence
Projet académique - SAE3 Mobile Development

---

## 🔄 Historique des versions

### v1.0.0 (Novembre 2025)
- ✅ CRUD feedbacks complet
- ✅ Modération locale avec bad_words.txt
- ✅ SQLite avec statistiques (AVG, COUNT, GROUP BY)
- ✅ Architecture propre et organisée
- ✅ Prêt pour intégration avec autres modules

---

**🎉 Bon courage pour l'intégration avec vos collègues !**
