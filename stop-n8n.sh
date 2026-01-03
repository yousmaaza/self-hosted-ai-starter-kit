#!/bin/bash

# Script d'arrêt n8n avec Ollama local
# Ce script arrête proprement tous les services

set -e  # Arrêter le script en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
    echo -e "${BLUE}    n8n + Ollama - Script d'arrêt${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
}

# Fonction pour arrêter les services Docker Compose
stop_docker_services() {
    print_info "Arrêt des services Docker Compose..."

    if docker compose ps | grep -q "Up"; then
        docker compose down
        print_success "Services Docker arrêtés"
    else
        print_warning "Aucun service Docker en cours d'exécution"
    fi
}

# Fonction pour arrêter Ollama (optionnel)
stop_ollama() {
    print_info "Voulez-vous également arrêter Ollama ? (y/N)"
    read -r -t 5 RESPONSE || RESPONSE="n"

    case "$RESPONSE" in
        [yY][eE][sS]|[yY])
            print_info "Arrêt d'Ollama..."
            brew services stop ollama
            print_success "Ollama arrêté"
            ;;
        *)
            print_info "Ollama reste en cours d'exécution"
            ;;
    esac
}

# Fonction pour afficher le statut final
show_final_status() {
    echo ""
    print_info "Statut final:"
    echo ""

    # Vérifier Docker
    if docker compose ps 2>/dev/null | grep -q "Up"; then
        print_warning "Certains services Docker sont encore en cours d'exécution"
        docker compose ps
    else
        print_success "Tous les services Docker sont arrêtés"

        # Vérifier spécifiquement le task runner
        if docker compose ps n8n-task-runner 2>/dev/null | grep -q "Up"; then
            print_info "Task runner Python encore actif"
        else
            print_success "Task runner Python arrêté"
        fi
    fi

    echo ""

    # Vérifier Ollama
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        print_info "Ollama est toujours en cours d'exécution sur le port 11434"
    else
        print_success "Ollama est arrêté"
    fi

    echo ""
}

# Script principal
main() {
    print_header

    stop_docker_services

    echo ""

    stop_ollama

    show_final_status

    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo -e "${GREEN}    Services arrêtés avec succès${NC}"
    echo -e "${GREEN}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}Pour redémarrer:${NC} ./start-n8n.sh"
    echo ""
}

# Gestion de l'interruption (Ctrl+C)
trap 'echo -e "\n${YELLOW}Script interrompu${NC}"; exit 130' INT

# Exécuter le script principal
main
