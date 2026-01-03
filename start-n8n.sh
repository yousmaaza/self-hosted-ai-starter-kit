#!/bin/bash

# Script de lancement n8n avec Ollama local
# Ce script vérifie les prérequis et démarre n8n automatiquement

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# URL de n8n
N8N_URL="http://localhost:5678"

# Fonction d'affichage
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}    n8n + Ollama - Script de lancement${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
}

# Fonction pour vérifier si une commande existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Fonction pour vérifier si Docker est en cours d'exécution
check_docker() {
    print_info "Vérification de Docker..."

    if ! command_exists docker; then
        print_error "Docker n'est pas installé"
        print_info "Installez Docker Desktop depuis: https://www.docker.com/products/docker-desktop"
        exit 1
    fi

    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker n'est pas en cours d'exécution"
        print_info "Lancez Docker Desktop et réessayez"
        exit 1
    fi

    print_success "Docker est opérationnel"
}

# Fonction pour vérifier si Ollama est en cours d'exécution
check_ollama() {
    print_info "Vérification d'Ollama..."

    if ! command_exists ollama; then
        print_warning "Ollama n'est pas installé"
        print_info "Installation d'Ollama via Homebrew..."

        if command_exists brew; then
            brew install ollama
            brew services start ollama
            sleep 3
        else
            print_error "Homebrew n'est pas installé"
            print_info "Installez Homebrew depuis: https://brew.sh"
            exit 1
        fi
    fi

    # Vérifier si le service Ollama répond
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        print_success "Ollama est opérationnel"

        # Afficher les modèles disponibles
        MODEL_COUNT=$(curl -s http://localhost:11434/api/tags | grep -o '"name"' | wc -l | xargs)
        if [ "$MODEL_COUNT" -gt 0 ]; then
            print_info "Modèles Ollama disponibles: $MODEL_COUNT"
        else
            print_warning "Aucun modèle Ollama installé"
            print_info "Téléchargez un modèle avec: ollama pull llama3.2"
        fi
    else
        print_warning "Ollama n'est pas en cours d'exécution"
        print_info "Démarrage d'Ollama..."
        brew services start ollama
        sleep 3

        if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            print_success "Ollama a été démarré avec succès"
        else
            print_error "Impossible de démarrer Ollama"
            exit 1
        fi
    fi
}

# Fonction pour vérifier si le fichier .env existe
check_env_file() {
    print_info "Vérification du fichier .env..."

    if [ ! -f .env ]; then
        print_warning "Le fichier .env n'existe pas"

        if [ -f .env.example ]; then
            print_info "Création du fichier .env depuis .env.example..."
            cp .env.example .env

            # Générer des secrets sécurisés
            print_info "Génération de secrets sécurisés..."
            ENCRYPTION_KEY=$(openssl rand -hex 32)
            JWT_SECRET=$(openssl rand -hex 32)
            PG_PASSWORD=$(openssl rand -hex 16)

            # Utiliser sed compatible macOS
            sed -i '' "s/N8N_ENCRYPTION_KEY=.*/N8N_ENCRYPTION_KEY=$ENCRYPTION_KEY/" .env
            sed -i '' "s/N8N_USER_MANAGEMENT_JWT_SECRET=.*/N8N_USER_MANAGEMENT_JWT_SECRET=$JWT_SECRET/" .env
            sed -i '' "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$PG_PASSWORD/" .env

            # Décommenter la ligne OLLAMA_HOST
            sed -i '' 's/# OLLAMA_HOST=/OLLAMA_HOST=/' .env

            print_success "Fichier .env créé et configuré"
        else
            print_error "Fichier .env.example introuvable"
            exit 1
        fi
    else
        print_success "Fichier .env trouvé"

        # Vérifier que OLLAMA_HOST est configuré
        if ! grep -q "^OLLAMA_HOST=host.docker.internal:11434" .env; then
            print_warning "OLLAMA_HOST n'est pas configuré correctement"
            print_info "Configuration de OLLAMA_HOST..."

            # Ajouter ou décommenter OLLAMA_HOST
            if grep -q "^# OLLAMA_HOST=" .env; then
                sed -i '' 's/^# OLLAMA_HOST=/OLLAMA_HOST=/' .env
            elif ! grep -q "OLLAMA_HOST=" .env; then
                echo "OLLAMA_HOST=host.docker.internal:11434" >> .env
            fi

            print_success "OLLAMA_HOST configuré"
        fi
    fi
}

# Fonction pour démarrer les services Docker Compose
start_services() {
    print_info "Démarrage des services Docker Compose..."

    # Vérifier si les conteneurs sont déjà en cours d'exécution
    if docker compose ps | grep -q "Up"; then
        print_info "Les services sont déjà en cours d'exécution"
        print_info "Redémarrage des services..."
        docker compose restart
    else
        docker compose up -d
    fi

    print_success "Services Docker Compose démarrés"
}

# Fonction pour attendre que n8n soit prêt
wait_for_n8n() {
    print_info "Attente du démarrage de n8n..."

    MAX_ATTEMPTS=30
    ATTEMPT=0

    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        if curl -s "$N8N_URL" >/dev/null 2>&1; then
            print_success "n8n est prêt !"
            return 0
        fi

        ATTEMPT=$((ATTEMPT + 1))
        echo -n "."
        sleep 2
    done

    echo ""
    print_error "n8n n'a pas démarré dans le temps imparti"
    print_info "Vérifiez les logs avec: docker compose logs n8n"
    return 1
}

# Fonction pour vérifier le task runner
check_task_runner() {
    print_info "Vérification du task runner Python..."

    # Vérifier si le conteneur task-runner existe et est en cours d'exécution
    if docker compose ps n8n-task-runner | grep -q "Up"; then
        print_success "Task runner Python opérationnel"

        # Vérifier les logs pour des erreurs éventuelles
        if docker compose logs n8n-task-runner 2>&1 | grep -qi "error\|failed"; then
            print_warning "Des erreurs ont été détectées dans les logs du task runner"
            print_info "Vérifiez avec: docker compose logs n8n-task-runner"
        fi
    else
        print_warning "Task runner non détecté ou arrêté"
        print_info "Le task runner est nécessaire pour exécuter du code Python dans n8n"
        print_info "Vérifiez les logs avec: docker compose logs n8n-task-runner"
    fi
}

# Fonction pour afficher le statut des services
show_status() {
    echo ""
    print_info "Statut des services:"
    echo ""
    docker compose ps
    echo ""
}

# Fonction pour ouvrir le navigateur
open_browser() {
    print_info "Ouverture de n8n dans le navigateur..."

    # Détecter le système d'exploitation et ouvrir le navigateur
    if command_exists open; then
        # macOS
        open "$N8N_URL"
    elif command_exists xdg-open; then
        # Linux
        xdg-open "$N8N_URL"
    elif command_exists start; then
        # Windows
        start "$N8N_URL"
    else
        print_warning "Impossible d'ouvrir le navigateur automatiquement"
        print_info "Accédez manuellement à: $N8N_URL"
        return 1
    fi

    print_success "Navigateur ouvert"
}

# Fonction pour afficher les informations finales
show_final_info() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}    n8n est maintenant accessible !${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BLUE}Interface n8n:${NC}     $N8N_URL"
    echo -e "  ${BLUE}Ollama API:${NC}       http://localhost:11434"
    echo -e "  ${BLUE}Qdrant:${NC}           http://localhost:6333"
    echo -e "  ${BLUE}Task Runner:${NC}      Python & JavaScript (port 5679)"
    echo ""
    echo -e "${YELLOW}Commandes utiles:${NC}"
    echo -e "  ${BLUE}Arrêter:${NC}          docker compose down"
    echo -e "  ${BLUE}Logs n8n:${NC}         docker compose logs -f n8n"
    echo -e "  ${BLUE}Logs runner:${NC}      docker compose logs -f n8n-task-runner"
    echo -e "  ${BLUE}Redémarrer:${NC}       ./start-n8n.sh"
    echo ""
}

# Script principal
main() {
    print_header

    # Vérifications préalables
    check_docker
    check_ollama
    check_env_file

    echo ""

    # Démarrage des services
    start_services

    # Attendre que n8n soit prêt
    if wait_for_n8n; then
        check_task_runner
        show_status
        open_browser
        show_final_info
    else
        show_status
        exit 1
    fi
}

# Gestion de l'interruption (Ctrl+C)
trap 'echo -e "\n${YELLOW}Script interrompu${NC}"; exit 130' INT

# Exécuter le script principal
main
