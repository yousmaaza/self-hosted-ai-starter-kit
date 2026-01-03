# Guide d'installation n8n avec Ollama local sur macOS

Ce guide détaille l'installation complète de n8n avec Ollama fonctionnant localement sur macOS pour des performances optimales.

## Table des matières

1. [Prérequis](#prérequis)
2. [Installation d'Ollama](#installation-dollama)
3. [Configuration du projet n8n](#configuration-du-projet-n8n)
4. [Démarrage des services](#démarrage-des-services)
5. [Accès à l'interface n8n](#accès-à-linterface-n8n)
6. [Commandes utiles](#commandes-utiles)
7. [Dépannage](#dépannage)

---

## Prérequis

Avant de commencer, assurez-vous d'avoir installé les éléments suivants :

### Vérifier les prérequis

```bash
# Vérifier Docker
docker --version
# Doit afficher : Docker version 24.x.x ou supérieur

# Vérifier Docker Compose
docker compose version
# Doit afficher : Docker Compose version v2.x.x ou supérieur

# Vérifier Git
git --version
# Doit afficher : git version 2.x.x ou supérieur

# Vérifier Homebrew
brew --version
# Doit afficher : Homebrew 4.x.x ou supérieur

# Vérifier que Docker est en cours d'exécution
docker ps
# Doit afficher la liste des conteneurs (peut être vide)
```

### Espace disque requis

- Minimum : 5 GB d'espace libre
- Recommandé : 10 GB ou plus

---

## Installation d'Ollama

Ollama est installé localement sur macOS pour bénéficier de l'accélération matérielle native (CPU/GPU Apple Silicon).

### Étape 1 : Installer Ollama via Homebrew

```bash
brew install ollama
```

### Étape 2 : Démarrer le service Ollama

```bash
brew services start ollama
```

### Étape 3 : Vérifier l'installation

```bash
# Vérifier que le service est actif
brew services list | grep ollama

# Tester l'API Ollama
curl http://localhost:11434/api/tags
```

Vous devriez voir une réponse JSON avec la liste des modèles disponibles.

### Étape 4 : Télécharger des modèles LLM (optionnel)

```bash
# Télécharger llama3.2 (recommandé pour débuter)
ollama pull llama3.2

# Autres modèles populaires
ollama pull mistral
ollama pull llama3.1
ollama pull codellama
```

---

## Configuration du projet n8n

### Étape 1 : Cloner le dépôt

```bash
cd ~/Documents/projets/n8n_folder
git clone https://github.com/n8n-io/self-hosted-ai-starter-kit.git
cd self-hosted-ai-starter-kit
```

### Étape 2 : Créer le fichier de configuration .env

```bash
cp .env.example .env
```

### Étape 3 : Générer des secrets sécurisés

```bash
# Générer une clé d'encryption
echo "N8N_ENCRYPTION_KEY=$(openssl rand -hex 32)" >> .env.tmp

# Générer un secret JWT
echo "N8N_USER_MANAGEMENT_JWT_SECRET=$(openssl rand -hex 32)" >> .env.tmp

# Générer un mot de passe PostgreSQL
echo "POSTGRES_PASSWORD=$(openssl rand -hex 16)" >> .env.tmp
```

### Étape 4 : Configurer le fichier .env

Éditez le fichier `.env` et configurez les valeurs suivantes :

```bash
# Base de données PostgreSQL
POSTGRES_USER=root
POSTGRES_PASSWORD=<votre_mot_de_passe_généré>
POSTGRES_DB=n8n

# Clés de sécurité n8n (à générer avec openssl)
N8N_ENCRYPTION_KEY=<votre_clé_générée>
N8N_USER_MANAGEMENT_JWT_SECRET=<votre_secret_généré>
N8N_DEFAULT_BINARY_DATA_MODE=filesystem

# Configuration Ollama pour macOS
# Cette ligne permet à n8n (dans Docker) d'accéder à Ollama (sur macOS)
OLLAMA_HOST=host.docker.internal:11434
```

**Important** : Décommentez la dernière ligne `OLLAMA_HOST` pour activer la connexion avec Ollama local.

### Étape 5 : Corriger le fichier docker-compose.yml (si nécessaire)

Si vous avez Docker Compose version < 2.23.0, vous devez simplifier la syntaxe `env_file` :

```yaml
# Remplacer dans docker-compose.yml (ligne 23-25)
env_file:
  - path: .env
    required: true

# Par :
env_file:
  - .env
```

---

## Démarrage des services

### Démarrage manuel

```bash
# Démarrer tous les services en arrière-plan
docker compose up -d

# Vérifier que les services sont en cours d'exécution
docker compose ps
```

Vous devriez voir :
- `n8n` (port 5678)
- `postgres` (healthy)
- `qdrant` (port 6333)

### Utilisation du script de lancement (recommandé)

```bash
# Rendre le script exécutable
chmod +x start-n8n.sh

# Lancer n8n
./start-n8n.sh
```

Le script va :
1. Vérifier que Docker est en cours d'exécution
2. Vérifier que Ollama est actif
3. Démarrer les services Docker Compose
4. Ouvrir automatiquement n8n dans votre navigateur

---

## Accès à l'interface n8n

### Première connexion

1. Ouvrez votre navigateur à l'adresse : **http://localhost:5678**

2. Créez votre compte administrateur :
   - Email
   - Prénom et nom
   - Mot de passe (minimum 8 caractères)

3. Une fois connecté, vous verrez le tableau de bord n8n avec des workflows de démonstration déjà importés.

### Tester la connexion avec Ollama

1. Allez dans **Settings** > **Credentials**
2. Cherchez les credentials Ollama
3. Vérifiez que l'URL est bien `http://host.docker.internal:11434`
4. Testez la connexion

---

## Commandes utiles

### Gestion de n8n (Docker)

```bash
# Démarrer n8n
docker compose up -d

# Arrêter n8n
docker compose down

# Redémarrer n8n
docker compose restart n8n

# Voir les logs en temps réel
docker compose logs -f n8n

# Voir les logs de tous les services
docker compose logs -f

# Vérifier le statut des services
docker compose ps

# Arrêter et supprimer tous les volumes (ATTENTION : perte de données)
docker compose down -v
```

### Gestion d'Ollama

```bash
# Démarrer Ollama
brew services start ollama

# Arrêter Ollama
brew services stop ollama

# Redémarrer Ollama
brew services restart ollama

# Voir le statut d'Ollama
brew services list | grep ollama

# Lister les modèles installés
ollama list

# Télécharger un nouveau modèle
ollama pull <nom_du_modèle>

# Supprimer un modèle
ollama rm <nom_du_modèle>

# Tester un modèle en ligne de commande
ollama run llama3.2 "Bonjour, qui es-tu ?"
```

### Gestion de Docker Desktop

```bash
# Redémarrer Docker Desktop (si problèmes)
# Via l'interface graphique ou :
killall Docker && open /Applications/Docker.app
```

---

## Dépannage

### n8n ne démarre pas

**Problème** : Le conteneur n8n redémarre en boucle

**Solution** :
```bash
# Vérifier les logs
docker compose logs n8n

# Vérifier que PostgreSQL est healthy
docker compose ps postgres

# Redémarrer tous les services
docker compose down
docker compose up -d
```

### Ollama n'est pas accessible depuis n8n

**Problème** : n8n ne peut pas se connecter à Ollama

**Solution** :
1. Vérifier qu'Ollama est bien en cours d'exécution :
   ```bash
   curl http://localhost:11434/api/tags
   ```

2. Vérifier la configuration dans `.env` :
   ```bash
   grep OLLAMA_HOST .env
   # Doit afficher : OLLAMA_HOST=host.docker.internal:11434
   ```

3. Redémarrer n8n :
   ```bash
   docker compose restart n8n
   ```

### Erreur "port already in use"

**Problème** : Le port 5678 ou 11434 est déjà utilisé

**Solution** :
```bash
# Trouver le processus utilisant le port
lsof -i :5678
lsof -i :11434

# Arrêter le processus ou changer le port dans docker-compose.yml
```

### Problème d'espace disque

**Problème** : Erreur "no space left on device"

**Solution** :
```bash
# Nettoyer les images Docker inutilisées
docker system prune -a

# Nettoyer les volumes Docker inutilisés
docker volume prune

# Vérifier l'espace disque
df -h
```

### Réinitialisation complète

Si vous souhaitez repartir de zéro :

```bash
# Arrêter et supprimer tous les conteneurs et volumes
docker compose down -v

# Supprimer les données locales
rm -rf .n8n

# Redémarrer l'installation
docker compose up -d
```

---

## Architecture du système

```
┌─────────────────────────────────────────────┐
│            macOS (Machine hôte)             │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  Ollama (local)                     │   │
│  │  Port: 11434                        │   │
│  │  Modèles: llama3.2, mistral, etc.  │   │
│  └─────────────────────────────────────┘   │
│                    ▲                        │
│                    │ host.docker.internal   │
│                    │                        │
│  ┌─────────────────────────────────────┐   │
│  │    Docker Compose                   │   │
│  │                                     │   │
│  │  ┌────────────┐  ┌──────────────┐  │   │
│  │  │    n8n     │  │  PostgreSQL  │  │   │
│  │  │  :5678     │──│              │  │   │
│  │  └────────────┘  └──────────────┘  │   │
│  │                                     │   │
│  │  ┌────────────┐                    │   │
│  │  │  Qdrant    │                    │   │
│  │  │  :6333     │                    │   │
│  │  └────────────┘                    │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## Ressources supplémentaires

- [Documentation officielle n8n](https://docs.n8n.io/)
- [Documentation Ollama](https://github.com/ollama/ollama)
- [GitHub du projet starter kit](https://github.com/n8n-io/self-hosted-ai-starter-kit)
- [Liste des modèles Ollama](https://ollama.com/library)

---

## Support

Si vous rencontrez des problèmes :

1. Consultez la section [Dépannage](#dépannage)
2. Vérifiez les logs : `docker compose logs -f`
3. Consultez les issues GitHub du projet
4. Rejoignez la communauté n8n sur Discord

---

**Version** : 1.0
**Dernière mise à jour** : Janvier 2026
**Système** : macOS (Apple Silicon & Intel)
