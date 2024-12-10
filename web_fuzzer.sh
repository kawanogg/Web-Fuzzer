#!/bin/bash

# Função para exibir ajuda
function show_help {
    echo "Uso: $0 -u TARGET_URL -w WORDLIST [-b GOBUSTER_IGNORE]"
    echo ""
    echo "  -u TARGET_URL          URL alvo (exemplo: http://example.com)"
    echo "  -w WORDLIST            Caminho para a wordlist de diretórios"
    echo "  -b GOBUSTER_IGNORE     (Opcional) Status codes para ignorar no Gobuster (ex.: 404,403)"
    exit 1
}

# Inicializa variáveis
TARGET_URL=""
WORDLIST=""
GOBUSTER_IGNORE=""

# Validar parâmetros
while getopts "u:w:b:" opt; do
    case "$opt" in
        u) TARGET_URL="$OPTARG" ;;
        w) WORDLIST="$OPTARG" ;;
        b) GOBUSTER_IGNORE="$OPTARG" ;;
        *) show_help ;;
    esac
done

# Verifica se os parâmetros obrigatórios foram fornecidos
if [[ -z "$TARGET_URL" || -z "$WORDLIST" ]]; then
    echo "Erro: Todos os parâmetros obrigatórios devem ser fornecidos."
    show_help
fi

# Função para executar o Gobuster para brute-force de diretórios
function run_gobuster_dirs {
    echo "[*] Iniciando brute-force de diretórios com Gobuster..."
    if [[ -n "$GOBUSTER_IGNORE" ]]; then
        gobuster dir -e -u "$TARGET_URL" -w "$WORDLIST" -t 100 -b "$GOBUSTER_IGNORE" -o gobuster_dir.txt -q
    else
        gobuster dir -e -u "$TARGET_URL" -w "$WORDLIST" -t 100 -o gobuster_dir.txt -q
    fi

    if [[ $? -eq 0 ]]; then
        echo "[+] Gobuster para diretórios finalizado. Resultados salvos em gobuster_dir.txt"
    else
        echo "[-] Erro ao executar Gobuster para diretórios!"
    fi
}

# Função para executar o Gobuster para verificação de Virtual Hosts
function run_gobuster_vhost {
    echo "[*] Iniciando verificação de Virtual Hosts com Gobuster..."
    if [[ -n "$GOBUSTER_IGNORE" ]]; then
        gobuster vhost -u $(echo "$TARGET_URL" | sed 's|^https\?://||') -w "$WORDLIST" -t 100 --append-domain -q --follow-redirect >> gobuster_vhost.txt
    fi

    if [[ $? -eq 0 ]]; then
        echo "[+] Gobuster para Virtual Hosts finalizado. Resultados salvos em gobuster_vhost.txt"
    else
        echo "[-] Erro ao executar Gobuster para Virtual Hosts!"
    fi
}

# Executar as funções em paralelo
run_gobuster_dirs &  # Subprocesso 1
PID_GOBUSTER_DIRS=$! # Armazena o PID do Gobuster Dirs

run_gobuster_vhost &      # Subprocesso 2
PID_GOBUSTER_VHOST=$!     # Armazena o PID do Gobuster Vhost

# Espera os subprocessos finalizarem
wait $PID_GOBUSTER_DIRS
wait $PID_GOBUSTER_VHOST

cat gobuster_vhost.txt | grep "200" | cut -d " " -f 2 >> gobuster_vhosts.txt
rm gobuster_vhost.txt 

echo "[*] Todos os testes foram concluídos. Confira os resultados nos arquivos de saída."
