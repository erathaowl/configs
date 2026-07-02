#!/usr/bin/env bash
#
# install_comfyui_nodes.sh
#
# Usage:
#   ./install_comfyui_nodes.sh lista.txt
#
# Lo script clona con --depth 1 ogni repo nella cartella custom_nodes/
# e installa i requisiti (requirements.txt o pyproject.toml) usando uv.

set -u  # errore su variabili non impostate

# ---------- Configurazione ----------
# Directory dove verranno clonati i nodi.
# Di default usa la directory dello script stesso (SCRIPT_DIR).
# Può essere sovrascritta con la variabile d'ambiente CUSTOM_NODES_DIR.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CUSTOM_NODES_DIR="${CUSTOM_NODES_DIR:-${SCRIPT_DIR}}"

# Colori per l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ---------- Controlli preliminari ----------
if [[ $# -lt 1 ]]; then
    echo -e "${RED}Uso: $0 <file_lista_repo>${NC}"
    exit 1
fi

# Converti il path del file lista in assoluto PRIMA di cambiare directory
LIST_FILE="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

if [[ ! -f "$LIST_FILE" ]]; then
    echo -e "${RED}File non trovato: $LIST_FILE${NC}"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}git non è installato.${NC}"
    exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
    echo -e "${RED}uv non è disponibile. Installalo con: curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
    exit 1
fi

mkdir -p "$CUSTOM_NODES_DIR"
cd "$CUSTOM_NODES_DIR" || exit 1

echo -e "${CYAN}Directory custom_nodes: $(pwd)${NC}"
echo -e "${CYAN}File lista: $LIST_FILE${NC}"
echo -e "${CYAN}Python: $(command -v python)${NC}"
echo -e "${CYAN}uv:     $(command -v uv)${NC}"
echo ""

# ---------- Contatori ----------
TOTAL=0
OK=0
FAIL=0
SKIP=0

# ---------- Funzione per installare i requisiti ----------
install_requirements() {
    local target_dir="$1"
    local req_file="$target_dir/requirements.txt"
    local pyproject_file="$target_dir/pyproject.toml"
    local installed=0

    # Priorità a requirements.txt se esiste
    if [[ -f "$req_file" ]]; then
        echo -e "  ${GREEN}Installo requirements.txt con uv...${NC}"
        if uv pip install -r "$req_file"; then
            echo -e "  ${GREEN}requirements.txt installato.${NC}"
            installed=1
        else
            echo -e "  ${RED}ERRORE nell'installazione di requirements.txt${NC}"
            return 1
        fi
    fi

    # Se non c'è requirements.txt, prova pyproject.toml
    if [[ $installed -eq 0 ]] && [[ -f "$pyproject_file" ]]; then
        echo -e "  ${GREEN}Installo dipendenze da pyproject.toml con uv...${NC}"
        # Usa -r per installare solo le dipendenze, non il pacchetto stesso
        if uv pip install -r "$pyproject_file"; then
            echo -e "  ${GREEN}Dipendenze da pyproject.toml installate.${NC}"
            installed=1
        else
            echo -e "  ${RED}ERRORE nell'installazione delle dipendenze da pyproject.toml${NC}"
            return 1
        fi
    fi

    # Se nessuno dei due esiste
    if [[ $installed -eq 0 ]]; then
        echo -e "  ${YELLOW}Nessun requirements.txt o pyproject.toml trovato.${NC}"
    fi

    return 0
}

# ---------- Loop sui repo ----------
while IFS= read -r line || [[ -n "$line" ]]; do
    # Rimuovi spazi a inizio/fine
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"

    # Salta righe vuote o commenti
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue

    # Deve contenere '='
    if [[ "$line" != *"="* ]]; then
        echo -e "${YELLOW}[SKIP] Riga non valida (manca '='): $line${NC}"
        ((SKIP++)) || true
        continue
    fi

    # Estrai nome e URL
    NAME="${line%%=*}"
    URL="${line#*=}"

    # Rimuovi eventuali spazi
    NAME="${NAME// /}"
    URL="${URL// /}"

    ((TOTAL++)) || true
    echo -e "${CYAN}[$TOTAL] $NAME${NC} -> $URL"

    TARGET_DIR="$CUSTOM_NODES_DIR/$NAME"

    # Clone o pull
    if [[ -d "$TARGET_DIR/.git" ]]; then
        echo -e "  ${YELLOW}Esiste già, aggiorno...${NC}"
        if ! git -C "$TARGET_DIR" pull --ff-only >/dev/null 2>&1; then
            echo -e "  ${YELLOW}Pull fallito, forzo reset a origin...${NC}"
            (
                cd "$TARGET_DIR" || exit 1
                git fetch --depth 1 origin >/dev/null 2>&1 || true
                git reset --hard FETCH_HEAD >/dev/null 2>&1 || true
            )
        fi
    else
        # Se esiste la cartella ma non è un repo git, la rimuovo per evitare conflitti
        if [[ -d "$TARGET_DIR" ]]; then
            echo -e "  ${YELLOW}Cartella esistente senza .git, la rimuovo...${NC}"
            rm -rf "$TARGET_DIR"
        fi
        echo -e "  ${GREEN}Clono con --depth 1...${NC}"
        if ! git clone --depth 1 "$URL" "$NAME" >/dev/null 2>&1; then
            echo -e "  ${RED}ERRORE: clone fallito per $NAME${NC}"
            ((FAIL++)) || true
            continue
        fi
    fi

    # Installazione requisiti
    if ! install_requirements "$TARGET_DIR"; then
        ((FAIL++)) || true
        continue
    fi

    ((OK++)) || true
    echo ""

done < "$LIST_FILE"

# ---------- Riepilogo ----------
echo ""
echo -e "${CYAN}================ RIEPILOGO ================${NC}"
echo -e "Totale righe processate: ${TOTAL}"
echo -e "${GREEN}Completate con successo : ${OK}${NC}"
echo -e "${YELLOW}Saltate (non valide)    : ${SKIP}${NC}"
echo -e "${RED}Fallite                 : ${FAIL}${NC}"
echo -e "${CYAN}===========================================${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0

