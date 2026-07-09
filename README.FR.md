# Simulateur Débogueur Autograf-882

![Simulateur Débogueur Autograf-882](images/Aftograf-882-Debuger.png)

Un débogueur et simulateur interactif pour le traceur **Autograf-882**, un traceur à plat soviétique basé sur le CPU **K580IK80A** (clone de l'Intel 8080), fonctionnant entièrement dans le navigateur.

Ce projet fournit un jumeau numérique complet du matériel d'origine : émulation CPU, entrées-sorties mappées en mémoire, désassembleur, simulation du traceur, terminal USART et chargeur de fichiers HPGL.

## Fonctionnalités

### Émulation CPU (cpu8080.js)
- Émulation complète du K580IK80A / Intel 8080 — les 256 opcodes
- Registres : A, B, C, D, E, H, L, SP, PC
- Drapeaux : S, Z, AC, P, CY (positions de bits 8080)
- Gestion des interruptions (INTR avec vecteur RST)
- Comptage de cycles T-state
- Contrôle de vitesse : max (illimité) jusqu'à 100 Hz

### Mémoire (memory.js)
- ROM : 24 Ko à `$0000–$5FFF` (trois EPROMs D2764A)
- RAM : 1 Ko à `$6000–$63FF` (KR537RU10)
- E/S mappées en mémoire : PPI1 à `$E000`, PPI2 à `$E400`, PIT à `$E800`, USART à `$EC00`
- Lectures non mappées retournent `$FF` ; écritures en ROM/non mappé sont enregistrées

### Désassembleur
- Désassembleur hybride récursif-linéaire basé sur la table d'opcodes CPU
- 6 colonnes : point d'arrêt, adresse, octets, mnémonique, opérandes, annotation
- Mode Follow-PC surligne l'instruction courante
- Défilement virtuel de tout l'espace d'adressage 64 Ko
- Clic pour basculer un point d'arrêt, double-clic pour sauter le PC
- Recherche par adresse (touche `J` saute à la ligne sous le curseur)

### Visualisation Mémoire
- Affichage avec défilement virtuel de tous les 64 Ko
- Régions colorées : ROM (gris), RAM (jaune), E/S (violet)
- Édition inline d'octets — clic sur un octet, édition en hex, Tab suivant
- Surbrillance du pointeur HL avec marqueur orange
- Barre d'adresse pour navigation rapide

### Simulation du Traceur
- Simulation des moteurs pas à pas XY depuis les phases du port PPI
- 7 couleurs de stylo (analyse du firmware)
- Canvas A4 portrait (1:√2) avec support Retina
- Grille à échelle automatique, curseur de position actuelle
- Boutons d'effacement et d'ajustement automatique

### Chargeur HPGL
- Chargement de fichiers HPGL : commandes `IN`, `SP`, `PU`, `PD`
- **Mode direct** : analyse et dessin avec animation
- **Mode UART** : envoi caractère par caractère du HPGL à l'USART
- Indicateur de progression et pause/reprise

### Terminal USART
- Champ de saisie hexadécimale pour envoyer des octets au CPU
- Chargement de fichier avec transfert XOn-XOff
- Journal de transmission avec caractères imprimables et codes hex
- Indicateurs TXRDY/RXRDY

### Sessions
- Sauvegarde complète de l'état CPU, RAM, points d'arrêt et lignes du traceur
- Sauvegarde en JSON avec horodatage
- Restauration depuis une session sauvegardée

### Aide
- Bouton `?` et touches `?`/`/` ouvrent une fenêtre d'aide
- Tableau des raccourcis clavier
- Guide des interactions souris

### Thèmes
- Thème sombre (défaut) — palette Tokyo Night
- Thème clair — palette lumineuse pour utilisation diurne
- Commutation dans le panneau Paramètres, persiste dans `localStorage`

## Exécution

```bash
cd ~/work/Antigravity/github/aftograf
python3 -m http.server 8080
```

Ouvrir `http://localhost:8080/sim/` dans un navigateur.

Le firmware (`firmware.bin`, 24 Ko) se charge automatiquement.  
Si absent, utiliser le bouton 📂 ou Paramètres → Charger le firmware.

## Raccourcis Clavier

| Touche | Action |
|---|---|
| `Espace` / `→` | Pas à pas (une instruction) |
| `R` | Reset CPU |
| `F5` | Exécuter / Pause |
| `B` | Basculer point d'arrêt sur PC |
| `J` | Sauter PC à l'adresse sous le curseur |
| `?` / `/` | Ouvrir l'aide |

---

**Autres langues :** [English](README.md) · [Русский](README.RU.md) · [Português](README.PT.md) · [Українська](README.UA.md) · [Français](README.FR.md) · [Deutsch](README.DE.md)
