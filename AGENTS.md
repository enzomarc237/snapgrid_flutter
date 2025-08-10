<general_rules>
- Avant de créer une nouvelle fonction ou utilitaire, vérifiez d'abord si une solution existe déjà dans le dossier concerné (`core/utils/`, `core/widgets/`, etc.). Si ce n'est pas le cas, ajoutez-la dans le dossier approprié ou créez un nouveau fichier si nécessaire.
- Respectez la structure modulaire : placez les fonctionnalités dans `features/` et les utilitaires partagés dans `core/`.
- Utilisez les conventions de nommage Dart et Flutter.
- Exécutez `flutter analyze` pour vérifier les erreurs et respecter les lints définis dans `analysis_options.yaml` (basé sur `flutter_lints`).
- Formatez le code avec `dart format .` avant de soumettre une PR.
- Les scripts courants incluent :  
  - `flutter pub get` pour installer les dépendances  
  - `flutter analyze` pour l'analyse statique  
  - `flutter test` pour exécuter les tests  
  - `flutter run -d <platform>` pour lancer l'application sur une plateforme spécifique
</general_rules>

<repository_structure>
- Le projet suit une architecture "clean architecture" :
  - `lib/core/` : utilitaires, thèmes, widgets réutilisables
  - `lib/features/` : modules fonctionnels (ex : `screenshots/`, `settings/`), chacun structuré en `data/`, `domain/`, `presentation/`
  - `lib/main.dart` : point d'entrée de l'application
- Dossiers spécifiques à chaque plateforme (`macos/`, `windows/`, `linux/`, `ios/`, `android/`) pour la configuration native.
- Les tests unitaires et widgets sont dans `test/` et suivent la structure du code source.
- Les assets sont dans `assets/images/`.
</repository_structure>

<dependencies_and_installation>
- Les dépendances sont gérées via `pubspec.yaml` avec `flutter pub get`.
- Utilisez la version de Flutter spécifiée dans `pubspec.yaml` (`sdk: ">=3.7.0 <4.0.0"`).
- Pour l'analyse IA, une clé API Gemini de Google est requise (à configurer dans l'application).
- Pour installer les dépendances :  
  ```sh
  flutter pub get
  ```
</dependencies_and_installation>

<testing_instructions>
- Les tests utilisent le framework `flutter_test` (voir `test/`).
- Pour exécuter tous les tests :
  ```sh
  flutter test
  ```
- Les tests unitaires couvrent les utilitaires, la logique métier et les widgets.
- Ajoutez des tests pour toute nouvelle fonctionnalité ou correction de bug.
- Les tests de widgets utilisent `testWidgets` pour simuler l'UI.
- Les tests sont organisés pour refléter la structure du code source.
</testing_instructions>

<pull_request_formatting>
</pull_request_formatting>
