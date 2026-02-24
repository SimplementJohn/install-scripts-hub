# 🛠 Scripts d’installation, activation et outils vidéo

Ce dépôt regroupe plusieurs scripts d’installation, d’activation et d’administration système.

---

# 📦 Installation des outils vidéo

## 🔹 mkvmerge.bat
Installe et configure **MKVToolNix (mkvmerge)** via Chocolatey.

**Fonctionnalités :**
- Installation automatique via Chocolatey
- Outils de fusion / édition de conteneurs MKV
- Ajout au PATH système

---

## 🔹 ffmpeg.bat
Installe **FFmpeg** via Chocolatey.

**Fonctionnalités :**
- Installation automatique
- Ajout au PATH
- Accès aux outils CLI audio / vidéo

---

# 🎬 Outils de conversion

## 🔹 videoToImg.ps1
Convertisseur vidéo → audio basé sur FFmpeg avec interface console interactive.

### Fonctionnalités :
- Sélection du fichier vidéo via fenêtre graphique
- Choix du nom de sortie
- Choix du format : `mp3`, `wav`, `aac`, `flac`
- Bandeau ASCII personnalisé
- Barre de progression en pourcentage
- Spinner d’activité
- La fenêtre PowerShell reste ouverte à la fin

---

# 🔐 Scripts d’activation

## 🔹 ActivateScriptPowershell.txt
Modèle de script PowerShell d’activation à copier / adapter selon le besoin.

---

## 🔹 KMS.ps1
Script PowerShell d’activation via serveur KMS.

---

# 🏢 Administration Active Directory

## 🔹 FSMOChecker.txt
Commande permettant de vérifier les rôles FSMO d’un domaine Active Directory.

### Commande :
```cmd
NETDOM QUERY /Domain:seemoine.local FSMO
