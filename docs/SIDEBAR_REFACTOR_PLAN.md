# Plan de refonte de la Sidebar et ajout de la gestion des catégories

Ce document détaille les étapes nécessaires pour réorganiser la `Sidebar` de l'application et intégrer une page dédiée à la gestion des catégories.

## Objectifs

*   Réorganiser la `Sidebar` pour une meilleure structure visuelle, inspirée de l'exemple fourni.
*   Créer une page distincte pour la gestion (ajout/visualisation) des catégories.
*   Implémenter le filtrage des captures d'écran basé sur la catégorie sélectionnée dans la `Sidebar`.

## Plan détaillé

1.  **Création de l'écran de gestion des catégories :**
    *   **Fichier :** `lib/features/categories/presentation/screens/manage_categories_screen.dart`
    *   **Widget :** `ManageCategoriesScreen` (ConsumerWidget)
    *   **UI :**
        *   Titre : "Gérer les catégories"
        *   Liste des catégories existantes (depuis `categoryListProvider`) avec options potentielles de suppression/édition.
        *   Champ de texte (`MacosTextField`) et bouton (`PushButton`) pour ajouter une nouvelle catégorie.
        *   Logique d'ajout/suppression utilisant `ref.read(categoryListProvider.notifier)`.
        *   Bouton "Retour" ou intégration dans la navigation.

2.  **Mise à jour de la navigation :**
    *   Modifier l'action du bouton "Gérer les catégories" (dans la `Sidebar` future) pour naviguer vers `ManageCategoriesScreen` (ex: `Navigator.push`).

3.  **Refonte de la `Sidebar` dans `main_screen.dart` :**
    *   Modifier le `builder` de `Sidebar`.
    *   Remplacer la `Column` actuelle par la structure suivante :
        ```mermaid
        graph TD
            A[Column] --> B(Padding + Text 'PAGES');
            A --> C(SidebarItem 'Screenshots');
            A --> D(SidebarItem 'Settings');
            A --> E(Padding + Text 'CATÉGORIES');
            A --> F{Liste des Catégories};
            A --> G(Spacer);
            A --> H(PushButton 'Gérer Catégories');

            subgraph Liste des Catégories
                direction TB
                F1(SidebarItem 'Toutes') --> F2(SidebarItem Catégorie 1);
                F2 --> F3(...);
                F3 --> F4(SidebarItem Catégorie N);
            end
        ```
    *   **Section PAGES :**
        *   Ajouter `Padding` + `Text` "PAGES" (style discret, majuscules).
        *   Placer `SidebarItem` "Screenshots" et "Settings" en dessous.
    *   **Section CATÉGORIES :**
        *   Ajouter `Padding` + `Text` "CATÉGORIES" (style idem).
        *   Ajouter `SidebarItem` "Toutes les catégories" (met `selectedCategoryIdProvider` à `null`).
        *   Lire `ref.watch(categoryListProvider)`.
        *   Créer une liste (`ListView`/`Column` dans `Expanded`) de `SidebarItem` pour chaque catégorie (avec icône + titre).
        *   Au clic, mettre à jour `selectedCategoryIdProvider` avec l'ID de la catégorie.
    *   **Bouton Gérer Catégories :**
        *   Ajouter `Spacer`.
        *   Ajouter `Padding` + `PushButton` "Gérer les catégories".
        *   Lier `onPressed` à la navigation vers `ManageCategoriesScreen`.
    *   **Nettoyage :** Supprimer l'ancien bouton "Create Categories" et son dialogue.

4.  **Implémentation du filtrage dans `ScreenshotGrid` :**
    *   **Fichier :** `lib/features/screenshots/presentation/widgets/screenshot_grid.dart`
    *   Écouter `ref.watch(selectedCategoryIdProvider)`.
    *   Filtrer les captures d'écran (issues de `screenshotsProvider`) en fonction de l'ID de catégorie sélectionné.

5.  **(Prérequis Potentiel) Mise à jour du modèle `Screenshot` :**
    *   **Fichier :** `lib/features/screenshots/domain/models/screenshot.dart`
    *   Vérifier/ajouter un champ `String? categoryId;` ou `List<String> categoryIds;`.
    *   Adapter la logique de sauvegarde/chargement des métadonnées si nécessaire.

## Schéma de la structure cible

```mermaid
graph TD
    subgraph Sidebar
        direction TB
        A[Section PAGES] --> B(Item Screenshots);
        A --> C(Item Settings);
        A --> D[Section CATÉGORIES];
        D --> E(Item Toutes);
        D --> F(Item Catégorie 1);
        D --> G(...);
        D --> H(Item Catégorie N);
        A --> I(Spacer);
        A --> J[Bouton Gérer Catégories];
    end

    J -- Navigue vers --> K[ManageCategoriesScreen];
    E -- Met à jour --> L(selectedCategoryIdProvider = null);
    F -- Met à jour --> M(selectedCategoryIdProvider = cat1.id);
    H -- Met à jour --> N(selectedCategoryIdProvider = catN.id);

    subgraph Contenu Principal
        O[ScreenshotGrid] -- Lit --> P(selectedCategoryIdProvider);
        O -- Filtre les données --> Q(Affichage Captures);
    end

    K -- Modifie --> R(categoryListProvider);
    D -- Lit --> R;