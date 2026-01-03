# n8n avec Ollama Local - Guide Rapide 🚀

Ce guide vous permet de démarrer rapidement n8n avec Ollama fonctionnant localement sur votre Mac pour des performances optimales.

## 📚 Documentation

Pour une documentation complète de l'installation, consultez : **[INSTALLATION.md](./INSTALLATION.md)**

## ⚡️ Démarrage rapide

### Option 1 : Utiliser le script de lancement (Recommandé)

Le moyen le plus simple pour démarrer n8n :

```bash
./start-n8n.sh
```

**Ce script va automatiquement :**
- ✅ Vérifier que Docker est en cours d'exécution
- ✅ Vérifier et démarrer Ollama si nécessaire
- ✅ Créer et configurer le fichier .env (s'il n'existe pas)
- ✅ Démarrer tous les services Docker
- ✅ Attendre que n8n soit prêt
- ✅ Ouvrir n8n dans votre navigateur

### Option 2 : Démarrage manuel

```bash
# 1. S'assurer qu'Ollama est en cours d'exécution
brew services start ollama

# 2. Démarrer les services Docker
docker compose up -d

# 3. Accéder à n8n
open http://localhost:5678
```

## 🛑 Arrêter les services

### Avec le script d'arrêt

```bash
./stop-n8n.sh
```

Le script vous demandera si vous souhaitez également arrêter Ollama.

### Arrêt manuel

```bash
# Arrêter les services Docker
docker compose down

# (Optionnel) Arrêter Ollama
brew services stop ollama
```

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir installé :

- ✅ **Docker Desktop** (version 24.x ou supérieure)
- ✅ **Docker Compose** (version 2.20.x ou supérieure)
- ✅ **Homebrew** (pour installer Ollama)
- ✅ **Git** (pour cloner le projet)

Le script `start-n8n.sh` installera automatiquement Ollama s'il n'est pas déjà installé.

## 🌐 Accès aux services

Une fois les services démarrés :

| Service | URL | Description |
|---------|-----|-------------|
| **n8n** | http://localhost:5678 | Interface principale de n8n |
| **Ollama API** | http://localhost:11434 | API Ollama pour les LLM |
| **Qdrant** | http://localhost:6333 | Base de données vectorielle |

## 📝 Commandes utiles

```bash
# Voir les logs de n8n
docker compose logs -f n8n

# Voir le statut de tous les services
docker compose ps

# Redémarrer n8n
docker compose restart n8n

# Lister les modèles Ollama
ollama list

# Télécharger un nouveau modèle
ollama pull llama3.2
```

## 🔧 Configuration

### Fichier .env

Le fichier `.env` contient toutes les variables d'environnement importantes :

```bash
# Connexion à Ollama local (déjà configuré par le script)
OLLAMA_HOST=host.docker.internal:11434

# Secrets générés automatiquement
N8N_ENCRYPTION_KEY=<généré automatiquement>
N8N_USER_MANAGEMENT_JWT_SECRET=<généré automatiquement>
POSTGRES_PASSWORD=<généré automatiquement>
```

### Première connexion à n8n

Lors de votre première visite sur http://localhost:5678 :

1. Créez votre compte administrateur
2. Explorez les workflows de démonstration préinstallés
3. Testez la connexion avec Ollama

## 🤖 Modèles Ollama recommandés

Pour débuter avec n8n :

```bash
# Modèle léger et rapide (3.2B paramètres)
ollama pull llama3.2

# Modèle polyvalent (7.2B paramètres)
ollama pull mistral

# Modèle plus puissant (8B paramètres)
ollama pull llama3.1

# Spécialisé pour le code
ollama pull codellama
```

## 🆘 Problèmes courants

### Docker n'est pas en cours d'exécution

```bash
# Ouvrir Docker Desktop manuellement
open -a Docker
```

### n8n ne démarre pas

```bash
# Vérifier les logs
docker compose logs n8n

# Redémarrer tous les services
docker compose down
docker compose up -d
```

### Ollama ne répond pas

```bash
# Redémarrer Ollama
brew services restart ollama

# Vérifier qu'il fonctionne
curl http://localhost:11434/api/tags
```

### Port déjà utilisé

```bash
# Trouver le processus utilisant le port 5678
lsof -i :5678

# Arrêter le processus ou modifier le port dans docker-compose.yml
```

## 📖 Documentation complète

Pour plus de détails sur :
- L'installation étape par étape
- La configuration avancée
- Le dépannage détaillé
- L'architecture du système

Consultez la **[Documentation complète (INSTALLATION.md)](./INSTALLATION.md)**

## 🔗 Ressources

- [Documentation officielle n8n](https://docs.n8n.io/)
- [Documentation Ollama](https://github.com/ollama/ollama)
- [Communauté n8n](https://community.n8n.io/)
- [Templates n8n AI](https://n8n.io/workflows/categories/ai/)

## 📞 Support

Besoin d'aide ?

1. Consultez la section dépannage de [INSTALLATION.md](./INSTALLATION.md)
2. Vérifiez les logs : `docker compose logs -f`
3. Rejoignez la [communauté n8n](https://community.n8n.io/)

---

**Version** : 1.0
**Système** : macOS (Apple Silicon & Intel)
**Date** : Janvier 2026
